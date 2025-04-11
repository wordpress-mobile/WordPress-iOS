import Foundation
import WordPressAPI
import AutomatticTracks
import SwiftUI
import AuthenticationServices
import WordPressKit
import WordPressAuthenticator
import WordPressShared
import SVProgressHUD

struct SelfHostedSiteAuthenticator {

    enum SignInContext: Equatable {
        // Sign in to a self-hosted site. Using this context results in automatically reloading the app to display the site dashboard.
        case `default`
        // Sign in to a site that's alredy added to the app. This is typically used when the app needs to get a new application password.
        case reauthentication(username: String?)
    }

    private static let callbackURL = URL(string: "x-wordpress-app://login-callback")!

    enum SignInError: Error, LocalizedError {
        case authentication(Error)
        case loadingSiteInfoFailure
        case savingSiteFailure
        case mismatchedUser(expectedUsername: String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .authentication(let error):
                return error.localizedDescription
            case .loadingSiteInfoFailure:
                return NSLocalizedString("addSite.selfHosted.loadingSiteInfoFailure", value: "Cannot load the WordPress site details", comment: "Error message shown when failing to load details from a self-hosted WordPress site")
            case .savingSiteFailure:
                return NSLocalizedString("addSite.selfHosted.savingSiteFailure", value: "Cannot save the WordPress site, please try again later.", comment: "Error message shown when failing to save a self-hosted site to user's device")
            case let .mismatchedUser(username):
                let format = NSLocalizedString("addSite.selfHosted.mismatchUser", value: "Please sign in with the logged in user. Username: %@", comment: "Error message when user signs in with an unexpected usern. The first argument is the expected username")
                return String(format: format, username)
            case .cancelled:
                return NSLocalizedString("addSite.selfHosted.cancelled", value: "Login has been cancelled", comment: "Error message when user cancels login")
            }
        }
    }

    private let internalClient: WordPressLoginClient

    init() {
        let session = URLSession(configuration: .ephemeral)
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
    func signIn(site: String, from viewController: UIViewController, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        do {
            let result = try await _signIn(site: site, from: viewController, context: context)
            trackSuccess(url: site)
            return result
        } catch {
            trackTypedError(error, url: site)
            throw error
        }
    }

    @MainActor
    private func _signIn(site: String, from viewController: UIViewController, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        do {
            let (apiRootURL, credentials) = try await authenticate(site: site, from: viewController)
            return try await handle(credentials: credentials, apiRootURL: apiRootURL, context: context)
        } catch let error as SignInError {
            throw error
        } catch {
            throw .authentication(error)
        }
    }

    @MainActor
    private func authenticate(site: String, from viewController: UIViewController) async throws -> (apiRootURL: URL, credentials: WpApiApplicationPasswordDetails) {
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

        let details = try await internalClient.details(ofSite: site)
        let loginURL = try details.loginURL(for: .init(id: appId, name: appNameValue, callbackUrl: SelfHostedSiteAuthenticator.callbackURL.absoluteString))
        let callback = try await authorize(url: loginURL, callbackURL: SelfHostedSiteAuthenticator.callbackURL, from: viewController)
        return (details.apiRootUrl.asURL(), try internalClient.credentials(from: callback))
    }

    @MainActor
    private func authorize(url: URL, callbackURL: URL, from viewController: UIViewController, prefersEphemeralWebBrowserSession: Bool = false) async throws -> URL {
        let provider = WebAuthenticationPresentationAnchorProvider(anchor: viewController.view.window ?? UIWindow())
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURL.scheme!
            ) { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: SignInError.cancelled)
                }
            }
            session.presentationContextProvider = provider
            session.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
            session.start()
        }
    }

    @MainActor
    private func handle(credentials: WpApiApplicationPasswordDetails, apiRootURL: URL, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        if case let .reauthentication(username) = context, let username, username != credentials.userLogin {
            throw .mismatchedUser(expectedUsername: username)
        }

        let xmlrpc: String
        let blogOptions: [AnyHashable: Any]
        do {
            xmlrpc = try credentials.derivedXMLRPCRoot.absoluteString
            blogOptions = try await loadSiteOptions(details: credentials)
        } catch {
            throw .loadingSiteInfoFailure
        }

        // Only store the new site after credentials are validated.
        let blog: TaggedManagedObjectID<Blog>
        do {
            blog = try await Blog.createRestApiBlog(with: credentials, restApiRootURL: apiRootURL, in: ContextManager.shared)
        } catch {
            throw .savingSiteFailure
        }

        let wporg = WordPressOrgCredentials(
            username: credentials.userLogin,
            password: credentials.password,
            xmlrpc: xmlrpc,
            options: blogOptions
        )

        SVProgressHUD.show()
        defer {
            SVProgressHUD.dismiss()
        }

        await withCheckedContinuation { continuation in
            WordPressAuthenticator.shared.delegate!.sync(credentials: .init(wporg: wporg)) {
                continuation.resume()
            }
        }

        if context == .default {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)
        }

        return blog
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
