import Foundation
import WordPressAPI
import AutomatticTracks

actor LoginClient {

    struct ApiDetails {
        let rootUrl: ParsedUrl
        let loginUrl: ParsedUrl
    }

    enum LoginClientError: Error {
        case missingLoginUrl
    }

    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func performLoginAutodiscovery(for url: URL) async throws -> ApiDetails {
        try await performLoginAutodiscovery(for: url.absoluteString)
    }

    func performLoginAutodiscovery(for string: String) async throws -> ApiDetails {
        let internalClient = WordPressLoginClient(urlSession: self.session)

        do {
            let result = try await internalClient.discoverLoginUrl(for: string)
            trackSuccess(url: string)

            // All sites should have some form of authentication we can use
            guard let passwordAuthenticationUrl = result.apiDetails.findApplicationPasswordsAuthenticationUrl() else {
                throw LoginClientError.missingLoginUrl
            }

            let details = ApiDetails(
                rootUrl: result.apiRootUrl,
                loginUrl: try ParsedUrl.parse(input: passwordAuthenticationUrl)
            )

            return details
        }
        catch let error as LoginClientError { // We can have nicer logging for typed errors
            trackTypedError(error, url: string)
            throw error
        }
        catch {
            await WordPressAppDelegate.crashLogging?.logError(error) // This might result in a *lot* of errors...
            trackError(error, url: string)
            throw error
        }
    }

    private func trackSuccess(url: String) {
        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": true
        ])
    }

    private func trackError(_ error: Error, url: String) {
        DDLogError("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": false
        ])
    }

    private func trackTypedError(_ error: LoginClient.LoginClientError, url: String) {
        DDLogError("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": false,
            "error": error.localizedDescription
        ])
    }
}
