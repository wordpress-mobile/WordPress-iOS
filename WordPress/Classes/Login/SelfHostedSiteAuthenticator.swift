import Foundation
import WordPressAPI
import WordPressAPIInternal
import AutomatticTracks
import SwiftUI
import AuthenticationServices
import WordPressData
import WordPressKit
import WordPressAuthenticator
import WordPressShared
import BuildSettingsKit
import SVProgressHUD

struct SelfHostedSiteAuthenticator {

    static var wordPressAppId: WpUuid {
        // The following UUIDs must be UUID v4.
        let uuid = switch BuildSettings.current.brand {
        case .wordpress:
            "a9cb72ed-311b-4f01-a0ac-a7af563d103e"
        case .jetpack:
            "7088f42d-34e9-4402-ab50-b506b819f3e4"
        case .reader:
            "d7753a1f-ec90-4fb5-80db-951929239796"
        }

        return try! WpUuid.parse(input: uuid)
    }

    static var wordPressAppName: String {
        let appName: String
        switch BuildSettings.current.brand {
        case .wordpress:
            appName = "WordPress"
        case .jetpack:
            appName = "Jetpack"
        case .reader:
            appName = "WordPress Reader"
        }

        let deviceName = UIDevice.current.name
        return "\(appName) iOS app on \(deviceName)"
    }

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

        // We need to manually check for cancellation, because `WordPressLoginClient` does not support Swift cancellation.
        if Task.isCancelled {
            throw .cancelled
        }

        return try await signIn(details: details, from: viewController, context: context)
    }

    @MainActor
    func signIn(details: AutoDiscoveryAttemptSuccess, from viewController: UIViewController, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        do {
            let (apiRootURL, credentials) = try await authenticate(details: details, from: viewController)
            let result = try await handle(credentials: credentials, apiRootURL: apiRootURL, apiDetails: details.apiDetails, context: context)
            trackSuccess(url: details.parsedSiteUrl.url())
            return result
        } catch {
            trackTypedError(error, url: details.parsedSiteUrl.url())
            throw error
        }
    }

    @MainActor
    private func authenticate(details: AutoDiscoveryAttemptSuccess, from viewController: UIViewController) async throws(SignInError) -> (apiRootURL: URL, credentials: WpApiApplicationPasswordDetails) {
        let appId = Self.wordPressAppId
        let appName = Self.wordPressAppName

        do {
            let loginURL = details.loginURL(for: .init(id: appId, name: appName, callbackUrl: SelfHostedSiteAuthenticator.callbackURL.absoluteString))
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
    private func handle(credentials: WpApiApplicationPasswordDetails, apiRootURL: URL, apiDetails: WpApiDetails, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        SVProgressHUD.show()
        defer {
            SVProgressHUD.dismiss()
        }

        if case let .reauthentication(_, username) = context, let username, username != credentials.userLogin {
            throw .mismatchedUser(expectedUsername: username)
        }

        let blog = try await createSite(credentials: credentials, apiRootURL: apiRootURL, apiDetails: apiDetails, context: context)

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

    private func createSite(
        credentials: WpApiApplicationPasswordDetails,
        apiRootURL: URL,
        apiDetails: WpApiDetails,
        context: SignInContext
    ) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        // We still need to set the `Blog.xmlrpc`, because it's used all across the app.
        let xmlrpc = (try? await discoverXMLRPCEndpoint(site: credentials.siteUrl))
            ?? URL(string: credentials.siteUrl)?.appending(component: "xmlrpc.php")
        guard let xmlrpc else {
            throw .loadingSiteInfoFailure
        }

        let api = WordPressAPI(
            urlSession: URLSession(configuration: .ephemeral),
            apiRootUrl: try! ParsedUrl.parse(input: apiRootURL.absoluteString),
            authentication: WpAuthentication(username: credentials.userLogin, password: credentials.password)
        )

        let siteSettings: SiteSettingsWithViewContext
        let isAdmin: Bool
        let jetpackSite: RemoteBlog?
        let jetpackConnection: JetpackConnectionData?
        let xmlrpcOptions: [AnyHashable: Any]?
        do {
            async let siteSettings_ = api.siteSettings.retrieveWithViewContext().data
            async let isAdmin_ = api.users.retrieveMeWithEditContext().data.roles.contains(.administrator)
            async let jetpackSite_ = fetchJetpackSite(apiRootURL: apiRootURL, credentials: credentials)
            async let jetpackConnection_ = fetchJetpackConnectionData(apiRootURL: apiRootURL, credentials: credentials)
            async let xmlrpcOptions_ = try? loadSiteOptions(xmlrpc: xmlrpc, details: credentials)

            (siteSettings, isAdmin, jetpackSite, jetpackConnection, xmlrpcOptions) =
                try await (siteSettings_, isAdmin_, jetpackSite_, jetpackConnection_, xmlrpcOptions_)
        } catch {
            throw .loadingSiteInfoFailure
        }

        let blog: TaggedManagedObjectID<Blog>
        do {
            blog = try await Blog.createRestApiBlog(
                with: credentials,
                restApiRootURL: apiRootURL,
                xmlrpcEndpointURL: xmlrpc,
                blogID: context.blogID,
                in: ContextManager.shared
            )

            try await ContextManager.shared.performAndSave { context in
                let blog = try context.existingObject(with: blog)

                blog.isAdmin = isAdmin
                blog.addSettingsIfNecessary()
                blog.settings?.name = siteSettings.title

                blog.options = (xmlrpcOptions ?? [:])
                    .merging(
                        (jetpackSite?.options as? [AnyHashable: Any] ?? [:]),
                        uniquingKeysWith: { _, jp in jp }
                    )

                // Set additional options if the site is fully connected to WP.com
                if let jetpackConnection, let dotComUser = jetpackConnection.currentUser.wpcomUser {
                    blog.setValue(dotComUser.login, forOption: "jetpack_user_login")
                    blog.setValue(dotComUser.email, forOption: "jetpack_user_email")
                    if let siteId = jetpackConnection.currentUser.blogId {
                        blog.setValue(siteId, forOption: "jetpack_client_id")
                    }

                    if let account = try? WPAccount.lookup(withUsername: dotComUser.login, in: context) {
                        blog.account = account
                    }
                }

                if blog.getOptionString(name: "blog_title") == nil {
                    blog.setValue(siteSettings.title, forOption: "blog_title")
                }

                if blog.getOptionString(name: "timezone") == nil {
                    blog.setValue(siteSettings.timezone, forOption: "timezone")
                }

                if blog.getOptionString(name: "gmt_offset") == nil, let offset = apiDetails.gmtOffset() {
                    blog.setValue(offset, forOption: "gmt_offset")
                }

                if blog.getOptionString(name: "home_url") == nil {
                    blog.setValue(apiDetails.homeUrlString(), forOption: "home_url")
                }
            }

            try await ApplicationPasswordRepository.shared.saveApplicationPassword(of: blog)
        } catch {
            throw .savingSiteFailure
        }

        return blog
    }

    private func fetchJetpackSite(apiRootURL: URL, credentials: WpApiApplicationPasswordDetails) async -> RemoteBlog? {
        // This endpoint proxies to WP.com public api `site/<site-id>` endpoint. When the site is connected to WP.com,
        // we can use this endpoint to get a full response of `RemoteBlog`, including the "options".
        guard let auth = "\(credentials.userLogin):\(credentials.password)".data(using: .utf8)?.base64EncodedString()
            else { return nil }

        struct SiteRequestResponse: Decodable {
            var code: String
            var data: String
        }

        var siteRequest = URLRequest(url: apiRootURL.appending(path: "/jetpack/v4/site"))
        siteRequest.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")

        // Ignoring the error cases, because the site may not connected to WP.com.
        guard let (data, response) = try? await URLSession.shared.data(for: siteRequest),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }

        do {
            let result = try JSONDecoder().decode(SiteRequestResponse.self, from: data)
            let site = try JSONSerialization.jsonObject(with: Data(result.data.utf8))
            if result.code == "success", let site = site as? NSDictionary {
                return RemoteBlog(jsonDictionary: site)
            } else {
                return nil
            }
        } catch {
            DDLogError("Failed to parse jetpack site response: \(error)")
            return nil
        }
    }

    private func fetchJetpackConnectionData(apiRootURL: URL, credentials: WpApiApplicationPasswordDetails) async -> JetpackConnectionData? {
        let delegate = WpApiClientDelegate(
            authProvider: .staticWithAuth(auth: .init(username: credentials.userLogin, password: credentials.password)),
            requestExecutor: WpRequestExecutor(urlSession: .init(configuration: .ephemeral)),
            middlewarePipeline: .default,
            appNotifier: EmptyAppNotifier()
        )
        let client = UniffiJetpackApiClient(apiUrlResolver: WpOrgSiteApiUrlResolver(apiRootUrl: try! ParsedUrl.from(url: apiRootURL)), delegate: delegate)
        return try? await client.connection().connectionData().data
    }
}

private final class EmptyAppNotifier: WpAppNotifier {
    func requestedWithInvalidAuthentication(requestUrl: String) async {
        // Do nothing.
    }
}
