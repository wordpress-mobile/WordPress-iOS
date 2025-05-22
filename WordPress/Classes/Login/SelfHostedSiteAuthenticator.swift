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

    static let applicationPasswordUpdated = Foundation.Notification.Name(rawValue: "SelfHostedSiteAuthenticator.applicationPasswordUpdated")

    enum SignInContext: Equatable {
        // Sign in to a self-hosted site. Using this context results in automatically reloading the app to display the site dashboard.
        case `default`
        // Sign in to a site that's alredy added to the app. This is typically used when the app needs to get a new application password.
        case reauthentication(TaggedManagedObjectID<Blog>, username: String?)

        var blogID: TaggedManagedObjectID<Blog>? {
            switch self {
            case .default:
                return nil
            case let .reauthentication(blogID, _):
                return blogID
            }
        }
    }

    private static let callbackURL = URL(string: "x-wordpress-app://login-callback")!

    enum SignInError: Error, LocalizedError {
        case authentication(Error)
        case xmlrpcDisabled(Error)
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
            case let .xmlrpcDisabled(underlying):
                if let reason = underlying as? WordPressOrgXMLRPCValidatorError {
                    return reason.localizedDescription
                } else {
                    return NSLocalizedString("addSite.selfHosted.xmlrpcDisabled", value: "Couldn't connect to the WordPress site. XML-RPC may have been disabled on the server. Please contact your hosting provider to solve this problem.", comment: "Error message when XML-RPC is disabled on the WordPress site. The first argument is detailed error message")
                }
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
            "error": "\(error)"
        ])
    }

    @MainActor
    func signIn(site: String, from viewController: UIViewController, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        let details: AutoDiscoveryAttemptSuccess
        do {
            details = try await internalClient.details(ofSite: site)
        } catch {
            trackTypedError(.authentication(error), url: site)
            throw .authentication(error)
        }

        return try await signIn(details: details, from: viewController, context: context)
    }

    @MainActor
    func signIn(details: AutoDiscoveryAttemptSuccess, from viewController: UIViewController, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        do {
            let (apiRootURL, credentials) = try await authenticate(details: details, from: viewController)
            let result = try await handle(credentials: credentials, apiRootURL: apiRootURL, context: context)
            trackSuccess(url: details.parsedSiteUrl.url())
            return result
        } catch {
            trackTypedError(error, url: details.parsedSiteUrl.url())
            throw error
        }
    }

    @MainActor
    private func authenticate(details: AutoDiscoveryAttemptSuccess, from viewController: UIViewController) async throws(SignInError) -> (apiRootURL: URL, credentials: WpApiApplicationPasswordDetails) {
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

        do {
            let loginURL = details.loginURL(for: .init(id: appId, name: appNameValue, callbackUrl: SelfHostedSiteAuthenticator.callbackURL.absoluteString))
            let callback = try await authorize(url: loginURL, callbackURL: SelfHostedSiteAuthenticator.callbackURL, from: viewController)
            return (details.apiRootUrl.asURL(), try internalClient.credentials(from: callback))
        } catch {
            throw .authentication(error)
        }
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
        SVProgressHUD.show()
        defer {
            SVProgressHUD.dismiss()
        }

        if case let .reauthentication(_, username) = context, let username, username != credentials.userLogin {
            throw .mismatchedUser(expectedUsername: username)
        }

        let xmlrpc: URL = try await discoverXMLRPCEndpoint(site: credentials.siteUrl)
        let blogOptions: [AnyHashable: Any]
        do {
            blogOptions = try await loadSiteOptions(xmlrpc: xmlrpc, details: credentials)
        } catch {
            throw .loadingSiteInfoFailure
        }

        // Only store the new site after credentials are validated.
        let blog: TaggedManagedObjectID<Blog>
        do {
            blog = try await Blog.createRestApiBlog(
                with: credentials,
                restApiRootURL: apiRootURL,
                xmlrpcEndpointURL: xmlrpc,
                blogID: context.blogID,
                in: ContextManager.shared
            )
        } catch {
            throw .savingSiteFailure
        }

        let accountPassword = try? await ContextManager.shared.performQuery {
            try $0.existingObject(with: blog).password
        }
        let wporg = WordPressOrgCredentials(
            username: credentials.userLogin,
            // The `sync` call below updates `Blog.password` with the password value here.
            // In order to separate `Blog.password` and `Blog.applicationPassword`, we pass the account password here
            // if it exists.
            password: accountPassword ?? credentials.password,
            xmlrpc: xmlrpc.absoluteString,
            options: blogOptions
        )

        await withCheckedContinuation { continuation in
            WordPressAuthenticator.shared.delegate!.sync(credentials: .init(wporg: wporg)) {
                continuation.resume()
            }
        }

        switch context {
        case .default:
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)
        case .reauthentication:
            NotificationCenter.default.post(name: Self.applicationPasswordUpdated, object: nil)
        }

        return blog
    }

    private func discoverXMLRPCEndpoint(site: String) async throws(SignInError) -> URL {
        do {
            let validator = WordPressOrgXMLRPCValidator()
            return try await withUnsafeThrowingContinuation { continuation in
                validator.guessXMLRPCURLForSite(
                    site,
                    userAgent: WPUserAgent.defaultUserAgent(),
                    success: { continuation.resume(returning: $0) },
                    failure: { continuation.resume(throwing: $0) }
                )
            }
        } catch {
            throw .xmlrpcDisabled(error)
        }
    }

    private func loadSiteOptions(xmlrpc: URL, details: WpApiApplicationPasswordDetails) async throws -> [AnyHashable: Any] {
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
