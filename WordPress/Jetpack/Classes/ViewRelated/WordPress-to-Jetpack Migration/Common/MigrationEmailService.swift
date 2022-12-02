import Foundation

final class MigrationEmailService {

    // MARK: - Dependencies

    private let api: WordPressComRestApi
    private let tracker: MigrationAnalyticsTracker

    // MARK: - Init

    init(api: WordPressComRestApi, tracker: MigrationAnalyticsTracker = .init()) {
        self.api = api
        self.tracker = tracker
    }

    convenience init(account: WPAccount) {
        self.init(api: account.wordPressComRestV2Api)
    }

    /// Convenience initializer that tries to set the `WordPressComRestApi` property, or fails.
    convenience init() throws {
        do {
            let context = ContextManager.shared.mainContext
            guard let account = try WPAccount.lookupDefaultWordPressComAccount(in: context) else {
                throw MigrationError.accountNotFound
            }
            self.init(api: account.wordPressComRestV2Api)
        } catch let error {
            DDLogError("[\(MigrationError.domain)] Object instantiation failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Methods

    func sendMigrationEmail() async throws {
        do {
            tracker.track(.emailTriggered)
            let response = try await sendMigrationEmail(path: Endpoint.migrationEmail)
            if !response.success {
                throw MigrationError.unsuccessfulResponse
            }
            tracker.track(.emailSent)
        } catch let error {
            let properties = ["error_type": error.localizedDescription]
            tracker.track(.emailFailed, properties: properties)
            DDLogError("[\(MigrationError.domain)] Migration email sending failed: \(error.localizedDescription)")
            throw error
        }
    }

    private func sendMigrationEmail(path: String) async throws -> SendMigrationEmailResponse {
        return try await withCheckedThrowingContinuation { continuation in
            api.POST(path, parameters: nil) { responseObject, httpResponse in
                do {
                    let decoder = JSONDecoder()
                    let data = try JSONSerialization.data(withJSONObject: responseObject)
                    let response = try decoder.decode(SendMigrationEmailResponse.self, from: data)
                    continuation.resume(returning: response)
                } catch let error {
                    continuation.resume(throwing: error)
                }
            } failure: { error, httpResponse in
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Types

    enum MigrationError: LocalizedError {
        case accountNotFound
        case unsuccessfulResponse

        var errorDescription: String? {
            switch self {
            case .accountNotFound: return "Account not found."
            case .unsuccessfulResponse: return "Backend returned an unsuccessful response. ( success: false )"
            }
        }

        static let domain = "MigrationEmailService"
    }

    private enum Endpoint {
        static let migrationEmail = "/wpcom/v2/mobile/migration"
    }

    private struct SendMigrationEmailResponse: Decodable {
        let success: Bool
    }
}
