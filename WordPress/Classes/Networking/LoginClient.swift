import Foundation
import WordPressAPI
import AutomatticTracks
import SwiftUI
import AuthenticationServices
import WordPressKit
import WordPressAuthenticator

final actor LoginClient {

    enum LoginClientError: Error {
        case authentication(WordPressLoginClient.Error)
        case loadingSiteInfoFailure
        case savingSiteFailure
    }

    private let internalClient: WordPressLoginClient

    init(session: URLSession) {
        self.internalClient = WordPressLoginClient(urlSession: session)
    }

    private func trackSuccess(url: String) {
        WPAnalytics.track(.applicationPasswordLogin, properties: [
            "url": url,
            "success": true
        ])
    }

    private func trackTypedError(_ error: LoginClient.LoginClientError, url: String) {
        DDLogError("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(.applicationPasswordLogin, properties: [
            "url": url,
            "success": false,
            "error": error.localizedDescription
        ])
    }

    @MainActor
    func login(site: String, from anchor: ASPresentationAnchor?) async -> Result<WordPressOrgCredentials, LoginClientError> {
        let appId: WpUuid
        let appName: String

        if AppConfiguration.isJetpack {
            appId = try! WpUuid.parse(input: "7088f42d-34e9-4402-ab50-b506b819f3e4")
            appName = "Jetpack iOS"
        } else {
            appId = try! WpUuid.parse(input: "a9cb72ed-311b-4f01-a0ac-a7af563d103e")
            appName = "WordPress iOS"
        }

        let deviceName = UIDevice.current.name
        let timestamp = ISO8601DateFormatter.string(from: .now, timeZone: .current, formatOptions: .withInternetDateTime)
        let appNameValue = "\(appName) - \(deviceName) (\(timestamp))"

        let result = await internalClient.login(
            site: site,
            appName: appNameValue,
            appId: appId,
            contextProvider: WebAuthenticationPresentationAnchorProvider(anchor: anchor ?? ASPresentationAnchor())
        )

        let returnValue: Result<WordPressOrgCredentials, LoginClientError>
        switch result {
        case let .failure(error):
            returnValue = .failure(.authentication(error))
        case let .success(success):
            returnValue = await handleSuccess(success)
        }

        switch returnValue {
        case .success:
            await trackSuccess(url: site)
        case let .failure(error):
            await trackTypedError(error, url: site)
        }

        return returnValue
    }

    func handleSuccess(_ success: WpApiApplicationPasswordDetails) async -> Result<WordPressOrgCredentials, LoginClientError> {
        let xmlrpc: String
        let blogOptions: [AnyHashable: Any]
        do {
            xmlrpc = try success.derivedXMLRPCRoot.absoluteString
            blogOptions = try await loadSiteOptions(details: success)
        } catch {
            return .failure(.loadingSiteInfoFailure)
        }

        // Only store the new site after credentials are validated.
        do {
            let _ = try await Blog.createRestApiBlog(with: success, in: ContextManager.shared)
        } catch {
            return .failure(.savingSiteFailure)
        }

        let wporg = WordPressOrgCredentials(
            username: success.userLogin,
            password: success.password,
            xmlrpc: xmlrpc,
            options: blogOptions
        )
        return .success(wporg)
    }

    private func loadSiteOptions(details: WpApiApplicationPasswordDetails) async throws -> [AnyHashable: Any] {
        let xmlrpc = try details.derivedXMLRPCRoot
        return try await withCheckedThrowingContinuation { continuation in
            let api = WordPressXMLRPCAPIFacade()
            api.getBlogOptions(withEndpoint: xmlrpc, username: details.userLogin, password: details.password) { options in
                continuation.resume(returning: options ?? [:])
            } failure: { error in
                continuation.resume(throwing: error ?? Blog.BlogCredentialsError.incorrectCredentials)
            }
        }
    }

}
