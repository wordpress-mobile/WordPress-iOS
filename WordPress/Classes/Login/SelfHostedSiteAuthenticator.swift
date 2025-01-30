import Foundation
import WordPressAPI
import AutomatticTracks
import SwiftUI
import AuthenticationServices
import WordPressKit
import WordPressAuthenticator

final actor SelfHostedSiteAuthenticator {

    enum SignInError: Error {
        case authentication(WordPressLoginClientError)
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

    private func trackTypedError(_ error: SelfHostedSiteAuthenticator.SignInError, url: String) {
        DDLogError("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(.applicationPasswordLogin, properties: [
            "url": url,
            "success": false,
            "error": error.localizedDescription
        ])
    }

    @MainActor
    func signIn(site: String, from anchor: ASPresentationAnchor?) async throws(SignInError) -> WordPressOrgCredentials {
        do {
            let result = try await _signIn(site: site, from: anchor)
            await trackSuccess(url: site)
            return result
        } catch {
            await trackTypedError(error, url: site)
            throw error
        }
    }

    @MainActor
    private func _signIn(site: String, from anchor: ASPresentationAnchor?) async throws(SignInError) -> WordPressOrgCredentials {
        let success: WpApiApplicationPasswordDetails
        do {
            success = try await authentication(site: site, from: anchor)
        } catch {
            throw .authentication(error)
        }

        return try await handleSuccess(success)
    }

    @MainActor
    func authentication(site: String, from anchor: ASPresentationAnchor?) async throws(WordPressLoginClientError) -> WpApiApplicationPasswordDetails {
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

        return try await internalClient.login(
            site: site,
            appName: appNameValue,
            appId: appId
        )
    }

    private func handleSuccess(_ success: WpApiApplicationPasswordDetails) async throws(SignInError) -> WordPressOrgCredentials {
        let xmlrpc: String
        let blogOptions: [AnyHashable: Any]
        do {
            xmlrpc = try success.derivedXMLRPCRoot.absoluteString
            blogOptions = try await loadSiteOptions(details: success)
        } catch {
            throw .loadingSiteInfoFailure
        }

        // Only store the new site after credentials are validated.
        do {
            let _ = try await Blog.createRestApiBlog(with: success, in: ContextManager.shared)
        } catch {
            throw .savingSiteFailure
        }

        let wporg = WordPressOrgCredentials(
            username: success.userLogin,
            password: success.password,
            xmlrpc: xmlrpc,
            options: blogOptions
        )
        return wporg
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
