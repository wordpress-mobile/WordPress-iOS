import Foundation
import WordPressAPI
import WordPressAPIInternal
import AutomatticTracks
import SwiftUI
import AuthenticationServices
import WordPressData
import WordPressKit
import WordPressShared
import BuildSettingsKit
import SVProgressHUD
import WordPressSharedUI

struct SelfHostedSiteAuthenticator {

    static var wordPressAppId: WpUuid {
        // The following UUIDs must be UUID v4.
        let uuid =
            switch BuildSettings.current.brand {
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

    static let applicationPasswordUpdated = Foundation.Notification.Name(
        rawValue: "SelfHostedSiteAuthenticator.applicationPasswordUpdated"
    )

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
        case xmlrpcEndpointNotFound
        case loadingSiteInfoFailure(Error)
        case savingSiteFailure
        case mismatchedUser(expectedUsername: String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .authentication(let error):
                return error.localizedDescription
            case .xmlrpcEndpointNotFound:
                return NSLocalizedString(
                    "addSite.selfHosted.xmlrpcEndpointNotFound",
                    value: "Could not determine the site's XML-RPC endpoint",
                    comment:
                        "Error message when the app cannot find the XML-RPC endpoint of a self-hosted WordPress site"
                )
            case .loadingSiteInfoFailure:
                return NSLocalizedString(
                    "addSite.selfHosted.loadingSiteInfoFailure",
                    value: "Cannot load the WordPress site details",
                    comment: "Error message shown when failing to load details from a self-hosted WordPress site"
                )
            case .savingSiteFailure:
                return NSLocalizedString(
                    "addSite.selfHosted.savingSiteFailure",
                    value: "Cannot save the WordPress site, please try again later.",
                    comment: "Error message shown when failing to save a self-hosted site to user's device"
                )
            case let .mismatchedUser(username):
                let format = NSLocalizedString(
                    "addSite.selfHosted.mismatchUser",
                    value: "Please sign in with the logged in user. Username: %@",
                    comment:
                        "Error message when user signs in with an unexpected usern. The first argument is the expected username"
                )
                return String(format: format, username)
            case .cancelled:
                return NSLocalizedString(
                    "addSite.selfHosted.cancelled",
                    value: "Login has been cancelled",
                    comment: "Error message when user cancels login"
                )
            case let .xmlrpcDisabled(underlying):
                if let reason = underlying as? WordPressOrgXMLRPCValidatorError {
                    return reason.localizedDescription
                } else {
                    return NSLocalizedString(
                        "addSite.selfHosted.xmlrpcDisabled",
                        value:
                            "Couldn't connect to the WordPress site. XML-RPC may have been disabled on the server. Please contact your hosting provider to solve this problem.",
                        comment:
                            "Error message when XML-RPC is disabled on the WordPress site. The first argument is detailed error message"
                    )
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
        WPAnalytics.track(
            .applicationPasswordLogin,
            properties: [
                "url": url,
                "success": true
            ]
        )
    }

    private func trackTypedError(_ error: SelfHostedSiteAuthenticator.SignInError, url: String) {
        Loggers.login.error("Unable to login to \(url): \(error.localizedDescription)")

        WPAnalytics.track(
            .applicationPasswordLogin,
            properties: [
                "url": url,
                "success": false,
                "error": "\(error)"
            ]
        )
    }

    @MainActor
    func signIn(
        site: String,
        from viewController: UIViewController,
        context: SignInContext
    ) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        let details: AutoDiscoveryAttemptSuccess
        do {
            details = try await internalClient.details(ofSite: site)
        } catch {
            logFailure("Failed to discover the self-hosted site, so sign-in cannot continue.", error: error)
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
    func signIn(
        details: AutoDiscoveryAttemptSuccess,
        from viewController: UIViewController,
        context: SignInContext
    ) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        do {
            let credentials: WpApiApplicationPasswordDetails
            if let parsed = parseCredentialsFromLaunchArguments(),
                details.parsedSiteUrl.url().contains(parsed.siteUrl)
            {
                credentials = parsed
            } else {
                credentials = try await authenticate(details: details, from: viewController)
            }

            let apiRootURL = details.apiRootUrl.asURL()
            let result = try await handle(
                credentials: credentials,
                apiRootURL: apiRootURL,
                apiDiscovery: details,
                context: context
            )
            trackSuccess(url: details.parsedSiteUrl.url())
            return result
        } catch {
            trackTypedError(error, url: details.parsedSiteUrl.url())
            throw error
        }
    }

    @MainActor
    private func authenticate(
        details: AutoDiscoveryAttemptSuccess,
        from viewController: UIViewController
    ) async throws(SignInError) -> WpApiApplicationPasswordDetails {
        guard case let .applicationPasswords(authURL) = details.authentication else {
            let failure = AutoDiscoveryAttemptFailure.FetchAndParseApiRoot(
                parsedSiteUrl: details.parsedSiteUrl,
                apiRootUrl: details.apiRootUrl,
                fetchAndParseApiRootFailure: .applicationPasswordsNotSupported(
                    apiDetails: details.apiDetails,
                    reason: nil
                )
            )
            throw .authentication(failure)
        }

        let appId = Self.wordPressAppId
        let appName = Self.wordPressAppName

        do {
            let loginURL = createApplicationPasswordAuthenticationUrl(
                loginUrl: authURL,
                appName: appName,
                appId: appId,
                successUrl: SelfHostedSiteAuthenticator.callbackURL.absoluteString,
                rejectUrl: SelfHostedSiteAuthenticator.callbackURL.absoluteString
            )
            .asURL()
            let callback = try await authorize(
                url: loginURL,
                callbackURL: SelfHostedSiteAuthenticator.callbackURL,
                from: viewController
            )
            return try internalClient.credentials(from: callback)
        } catch {
            throw .authentication(error)
        }
    }

    @MainActor
    private func authorize(
        url: URL,
        callbackURL: URL,
        from viewController: UIViewController,
        prefersEphemeralWebBrowserSession: Bool = false
    ) async throws -> URL {
        let provider = WebAuthenticationPresentationAnchorProvider(anchor: viewController.view.window ?? UIWindow())
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURL.scheme!
            ) { url, _ in
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
    private func handle(
        credentials: WpApiApplicationPasswordDetails,
        apiRootURL: URL,
        apiDiscovery: AutoDiscoveryAttemptSuccess,
        context: SignInContext
    ) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        SVProgressHUD.show()
        defer {
            SVProgressHUD.dismiss()
        }

        if case let .reauthentication(_, username) = context, let username, username != credentials.userLogin {
            throw .mismatchedUser(expectedUsername: username)
        }

        let blog = try await createSite(
            credentials: credentials,
            apiRootURL: apiRootURL,
            apiDiscovery: apiDiscovery,
            context: context
        )

        switch context {
        case .default:
            NotificationCenter.default.post(
                name: Foundation.Notification.Name(
                    rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification
                ),
                object: nil
            )
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

    private func loadSiteOptions(
        xmlrpc: URL,
        details: WpApiApplicationPasswordDetails
    ) async throws -> [AnyHashable: Any] {
        try await withCheckedThrowingContinuation { continuation in
            let api = WordPressOrgXMLRPCApi(endpoint: xmlrpc, userAgent: nil)
            api.checkCredentials(details.userLogin, password: details.password) { responseObject, _ in
                if let options = responseObject as? [AnyHashable: Any] {
                    continuation.resume(returning: options)
                } else {
                    continuation.resume(throwing: WordPressOrgXMLRPCApiError.responseSerializationFailed)
                }
            } failure: { error, _ in
                continuation.resume(throwing: error)
            }
        }
    }

    private func createSite(
        credentials: WpApiApplicationPasswordDetails,
        apiRootURL: URL,
        apiDiscovery: AutoDiscoveryAttemptSuccess,
        context: SignInContext
    ) async throws(SignInError) -> TaggedManagedObjectID<Blog> {
        // We still need to set the `Blog.xmlrpc`, because it's used all across the app.
        let xmlrpc: URL
        do {
            xmlrpc = try await discoverXMLRPCEndpoint(site: credentials.siteUrl)
        } catch {
            guard let fallback = URL(string: credentials.siteUrl)?.appending(component: "xmlrpc.php") else {
                logFailure("Failed to find the site's XML-RPC endpoint, so sign-in cannot continue.", error: error)
                throw .xmlrpcEndpointNotFound
            }
            logFailure(
                "Failed to find the site's XML-RPC endpoint. Sign-in will use the default endpoint.",
                error: error
            )
            xmlrpc = fallback
        }

        let api = WordPressAPI(
            urlSession: URLSession(configuration: .ephemeral),
            siteInfo: .selfHosted(
                siteUrl: apiDiscovery.parsedSiteUrl,
                apiRoot: apiDiscovery.apiRootUrl
            ),
            authentication: WpAuthentication(username: credentials.userLogin, password: credentials.password)
        )

        let siteSettings: SiteSettingsWithViewContext?
        let isAdmin: Bool
        let jetpackSite: RemoteBlog?
        let jetpackConnection: JetpackConnectionData?
        let xmlrpcOptions: [AnyHashable: Any]?
        do {
            // site settings is only available to admin users. Ignore errors for now,
            // since we need to allow other users to sign in to the app too.
            async let siteSettings_: SiteSettingsWithViewContext? = {
                do {
                    return try await api.siteSettings.retrieveWithViewContext().data
                } catch {
                    logFailure("Failed to load the site's settings. Sign-in will continue without them.", error: error)
                    return nil
                }
            }()
            async let isAdmin_ = api.users.retrieveMeWithEditContext().data.roles.contains(.administrator)
            async let jetpackSite_ = fetchJetpackSite(apiRootURL: apiRootURL, credentials: credentials)
            async let jetpackConnection_ = fetchJetpackConnectionData(apiRootURL: apiRootURL, credentials: credentials)
            async let xmlrpcOptions_: [AnyHashable: Any]? = {
                do {
                    return try await loadSiteOptions(xmlrpc: xmlrpc, details: credentials)
                } catch {
                    logFailure(
                        "Failed to load the site's XML-RPC options. Sign-in will continue without them.",
                        error: error
                    )
                    return nil
                }
            }()

            (siteSettings, isAdmin, jetpackSite, jetpackConnection, xmlrpcOptions) =
                try await (siteSettings_, isAdmin_, jetpackSite_, jetpackConnection_, xmlrpcOptions_)
        } catch {
            logFailure("Failed to load the current user, so sign-in cannot continue.", error: error)
            throw .loadingSiteInfoFailure(error)
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
                blog.settings?.name = siteSettings?.title

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

                if blog.getOptionString(name: "blog_title") == nil, let title = siteSettings?.title {
                    blog.setValue(title, forOption: "blog_title")
                }

                if blog.getOptionString(name: "timezone") == nil, let timezone = siteSettings?.timezone {
                    blog.setValue(timezone, forOption: "timezone")
                }

                if blog.getOptionString(name: "gmt_offset") == nil, let offset = apiDiscovery.apiDetails.gmtOffset() {
                    blog.setValue(offset, forOption: "gmt_offset")
                }

                if blog.getOptionString(name: "home_url") == nil {
                    blog.setValue(apiDiscovery.apiDetails.homeUrlString(), forOption: "home_url")
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
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: siteRequest)
        } catch {
            logFailure("Failed to load the Jetpack site information. Sign-in will continue without it.", error: error)
            return nil
        }

        guard let response = response as? HTTPURLResponse else {
            Loggers.login.error(
                "The Jetpack site request returned an invalid response. Sign-in will continue without it."
            )
            return nil
        }
        guard response.statusCode == 200 else {
            Loggers.login.error(
                "The Jetpack site request returned HTTP status \(response.statusCode). Sign-in will continue without it."
            )
            return nil
        }

        do {
            let result = try JSONDecoder().decode(SiteRequestResponse.self, from: data)
            let site = try JSONSerialization.jsonObject(with: Data(result.data.utf8))
            guard result.code == "success" else {
                Loggers.login.error(
                    "The Jetpack site request failed with error code \(result.code). Sign-in will continue without it."
                )
                return nil
            }
            guard let site = site as? NSDictionary else {
                Loggers.login.error("The Jetpack site response could not be decoded. Sign-in will continue without it.")
                return nil
            }
            return RemoteBlog(jsonDictionary: site)
        } catch {
            logFailure("Failed to decode the Jetpack site response. Sign-in will continue without it.", error: error)
            return nil
        }
    }

    private func fetchJetpackConnectionData(
        apiRootURL: URL,
        credentials: WpApiApplicationPasswordDetails
    ) async -> JetpackConnectionData? {
        let delegate = WpApiClientDelegate(
            authProvider: .staticWithAuth(auth: .init(username: credentials.userLogin, password: credentials.password)),
            requestExecutor: WpRequestExecutor(urlSession: .init(configuration: .ephemeral)),
            middlewarePipeline: .default,
            appNotifier: EmptyAppNotifier()
        )
        let client = UniffiJetpackApiClient(
            apiUrlResolver: WpOrgSiteApiUrlResolver(apiRootUrl: try! ParsedUrl.from(url: apiRootURL)),
            delegate: delegate
        )
        do {
            return try await client.connection().connectionData().data
        } catch {
            logFailure(
                "Failed to load the Jetpack connection information. Sign-in will continue without it.",
                error: error
            )
            return nil
        }
    }

    private func parseCredentialsFromLaunchArguments() -> WpApiApplicationPasswordDetails? {
        let defaults = UserDefaults.standard
        guard let siteURL = defaults.string(forKey: "ui-test-site-url"),
            let user = defaults.string(forKey: "ui-test-site-user"),
            let pass = defaults.string(forKey: "ui-test-site-pass")
        else {
            return nil
        }

        return .init(siteUrl: siteURL, userLogin: user, password: pass)
    }
}

private extension SelfHostedSiteAuthenticator {
    func logFailure(_ message: String, error: Error) {
        Loggers.login.error("\(message)")
        log(error: error)
    }

    func log(error: Error) {
        switch error {
        case let error as AutoDiscoveryAttemptFailure:
            log(error: error)
        case let error as WpApiError:
            log(error: error)
        case let error as RequestExecutionError:
            log(error: error)
        case is DecodingError:
            Loggers.login.error("The self-hosted response could not be decoded.")
        case let error as URLError:
            Loggers.login.error(
                "The self-hosted request failed with a URL error. The error code was url_error_\(error.errorCode)."
            )
        case let error as WordPressOrgXMLRPCValidatorError:
            Loggers.login.error(
                "The site's XML-RPC endpoint could not be validated. The error code was validator_\(error.rawValue)."
            )
        case let error as WordPressOrgXMLRPCApiError:
            Loggers.login.error("The site's XML-RPC request failed. The error code was api_\(error.rawValue).")
        default:
            let error = error as NSError
            Loggers.login.error(
                "The self-hosted request failed with an unexpected error. The error domain was \(error.domain), and the error code was \(error.code)."
            )
        }
    }

    func log(error: AutoDiscoveryAttemptFailure) {
        switch error {
        case .ParseSiteUrl:
            Loggers.login.error("The site URL could not be parsed.")
        case .FindApiRoot(_, .fetchHomepage(let error)),
            .FetchAndParseApiRoot(_, _, .fetchApiRoot(let error)):
            log(error: error)
        case .FindApiRoot(_, .probablyNotAWordPressSite):
            Loggers.login.error("The site does not appear to be a WordPress site.")
        case .FindApiRoot(_, .restApiDisabled):
            Loggers.login.error("The site's REST API is disabled.")
        case .FetchAndParseApiRoot(_, _, .parseApiRoot):
            Loggers.login.error("The site's REST API response could not be decoded.")
        case .FetchAndParseApiRoot(_, _, .wpError(let errorCode, _, let statusCode)):
            Loggers.login.error(
                "The WordPress REST API request failed. The HTTP status code was \(statusCode). The error code was \(errorCode)."
            )
        case .FetchAndParseApiRoot(_, _, .applicationPasswordsNotSupported):
            Loggers.login.error("The site does not support application passwords.")
        }
    }

    func log(error: WpApiError) {
        switch error {
        case .InvalidHttpStatusCode(let statusCode, _, _):
            Loggers.login.error(
                "The self-hosted request returned an unexpected HTTP status. The HTTP status code was \(statusCode)."
            )
        case .RequestExecutionFailed(let statusCode, _, let reason, _, _):
            logRequestExecutionFailure(statusCode: statusCode, reason: reason)
        case .MediaFileNotFound:
            Loggers.login.error("The requested media file was not found.")
        case .ResponseParsingError:
            Loggers.login.error("The WordPress REST API response could not be decoded.")
        case .SiteUrlParsingError:
            Loggers.login.error("The site URL could not be parsed.")
        case .UnknownError(let statusCode, _, _, _):
            Loggers.login.error(
                "The self-hosted request failed with an unknown HTTP error. The HTTP status code was \(statusCode)."
            )
        case .WpError(let errorCode, _, let statusCode, _, _, _):
            Loggers.login.error(
                "The WordPress REST API request failed. The HTTP status code was \(statusCode). The error code was \(errorCode)."
            )
        }
    }

    func log(error: RequestExecutionError) {
        switch error {
        case .RequestExecutionFailed(let statusCode, _, let reason, _, _):
            logRequestExecutionFailure(statusCode: statusCode, reason: reason)
        case .MediaFileNotFound:
            Loggers.login.error("The requested media file was not found.")
        }
    }

    func logRequestExecutionFailure(statusCode: UInt32?, reason: RequestExecutionErrorReason) {
        if let statusCode {
            Loggers.login.error(
                "The self-hosted request could not be completed. The HTTP status code was \(statusCode). The error was \(reason)."
            )
        } else {
            Loggers.login.error("The self-hosted request could not be completed. The error was \(reason).")
        }
    }
}

private final class EmptyAppNotifier: WpAppNotifier {
    func requestedWithInvalidAuthentication(requestUrl: String) async {
        // Do nothing.
    }
}
