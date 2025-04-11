import Foundation
import WordPressAPI
import AutomatticTracks
import SwiftUI
import AuthenticationServices
import WordPressKit
import WordPressAuthenticator
import WordPressShared

final actor SelfHostedSiteAuthenticator {

    private static let callbackURL = URL(string: "x-wordpress-app://login-callback")!

    enum SignInError: Error, LocalizedError {
        case authentication(Error)
        case loadingSiteInfoFailure
        case savingSiteFailure
        case invalidApplicationPasswordCallback
        case cancelled

        var errorDescription: String? {
            switch self {
            case .authentication(let error):
                return error.localizedDescription
            case .loadingSiteInfoFailure:
                return NSLocalizedString("addSite.selfHosted.loadingSiteInfoFailure", value: "Cannot load the WordPress site details", comment: "Error message shown when failing to load details from a self-hosted WordPress site")
            case .savingSiteFailure:
                return NSLocalizedString("addSite.selfHosted.savingSiteFailure", value: "Cannot save the WordPress site, please try again later.", comment: "Error message shown when failing to save a self-hosted site to user's device")
            case .invalidApplicationPasswordCallback:
                return NSLocalizedString("addSite.selfHosted.authenticationFailed", value: "Cannot login using Application Password authentication.", comment: "Error message shown when an receiving an invalid application-password authentication result from a self-hosted WordPress site")
            case .cancelled:
                return nil
            }
        }
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
    func signIn(site: String, from anchor: ASPresentationAnchor) async throws(SignInError) -> WordPressOrgCredentials {
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
    private func _signIn(site: String, from anchor: ASPresentationAnchor) async throws(SignInError) -> WordPressOrgCredentials {
        let success: WpApiApplicationPasswordDetails
        do {
            success = try await authentication(site: site, from: anchor)
        } catch let error as SignInError {
            throw error
        } catch {
            throw .authentication(error)
        }

        return try await handleSuccess(success)
    }

    @MainActor
    func authentication(site: String, from anchor: ASPresentationAnchor) async throws -> WpApiApplicationPasswordDetails {
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

        let loginURL = try await internalClient.loginURL(forSite: site, application: .init(id: appId, name: appNameValue, callbackUrl: SelfHostedSiteAuthenticator.callbackURL.absoluteString))
        let callback = try await authenticate(url: loginURL, callbackURL: SelfHostedSiteAuthenticator.callbackURL, from: anchor)
        return try internalClient.credentials(from: callback)
    }

    @MainActor
    func authenticate(url: URL, callbackURL: URL, from anchor: ASPresentationAnchor) async throws -> URL {
        let provider = WebAuthenticationPresentationAnchorProvider(anchor: anchor)
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURL.scheme!
            ) { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else if let error = error as? ASWebAuthenticationSessionError {
                    switch error.code {
                    case .canceledLogin:
                        assertionFailure("An unexpected error received: \(error)")
                        continuation.resume(throwing: SignInError.cancelled)
                    case .presentationContextInvalid, .presentationContextNotProvided:
                        assertionFailure("An unexpected error received: \(error)")
                        continuation.resume(throwing: SignInError.cancelled)
                    @unknown default:
                        assertionFailure("An unexpected error received: \(error)")
                        continuation.resume(throwing: SignInError.cancelled)
                    }
                } else {
                     continuation.resume(throwing: SignInError.invalidApplicationPasswordCallback)
                }
            }
            session.presentationContextProvider = provider
            session.start()
        }
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
