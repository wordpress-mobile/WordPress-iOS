import Foundation
import Combine
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData
import WordPressShared

extension WordPressClient {
    static var requestedWithInvalidAuthenticationNotification: Foundation.Notification.Name {
        .init("WordPressClient.requestedWithInvalidAuthenticationNotification")
    }

    init(site: WordPressSite) {
        // Currently, the app supports both account passwords and application passwords.
        // When a site is initially signed in with an account password, WordPress login cookies are stored
        // in `URLSession.shared`. After switching the site to application password authentication,
        // the stored cookies may interfere with application-password authentication, resulting in 401
        // errors from the REST API.
        //
        // To avoid this issue, we'll use an ephemeral URLSession for now (which stores cookies in memory
        // rather than using the shared one on disk).
        let session = URLSession(configuration: .ephemeral)

        let notifier = AppNotifier()
        let provider = WpAuthenticationProvider.dynamic(
            dynamicAuthenticationProvider: AutoUpdateAuthenticationProvider(site: site, coreDataStack: ContextManager.shared)
        )
        let apiRootURL: ParsedUrl
        let resolver: ApiUrlResolver
        switch site {
        case let .dotCom(siteId, _):
            apiRootURL = try! ParsedUrl.parse(input: "https://public-api.wordpress.com/wp/v2/site/\(siteId)")
            resolver = WpComDotOrgApiUrlResolver(siteUrl: "\(siteId)")
        case let .selfHosted(_, url, _, _):
            apiRootURL = url
            resolver = WpOrgSiteApiUrlResolver(apiRootUrl: url)
        }
        let api = WordPressAPI(
            urlSession: session,
            apiUrlResolver: resolver,
            authenticationProvider: provider,
            appNotifier: notifier
        )
        notifier.api = api
        self.init(api: api, rootUrl: apiRootURL)
    }

    func installJetpack() async throws -> PluginWithEditContext {
        try await self.api.plugins.create(params: PluginCreateParams(
            slug: "InstallJetpack",
            status: .active
        )).data
    }
}

extension PluginWpOrgDirectorySlug: @retroactive ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral: String) {
        self.init(slug: stringLiteral)
    }
}

private final class AutoUpdateAuthenticationProvider: @unchecked Sendable, WpDynamicAuthenticationProvider {
    private let lock = NSLock()
    private let site: WordPressSite
    private let coreDataStack: CoreDataStack
    private var authentication: WpAuthentication
    private var cancellable: AnyCancellable?

    init(site: WordPressSite, coreDataStack: CoreDataStack) {
        self.site = site
        self.coreDataStack = coreDataStack
        self.authentication = switch site {
        case let .dotCom(_, authToken):
            .bearer(token: authToken)
        case let .selfHosted(_, _, username, authToken):
            .init(username: username, password: authToken)
        }

        self.cancellable = NotificationCenter.default.publisher(for: SelfHostedSiteAuthenticator.applicationPasswordUpdated).sink { [weak self] _ in
            self?.update()
        }
    }

    func update() {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }

        self.authentication = coreDataStack.performQuery { [site] context in
            switch site {
            case let .dotCom(siteId, _):
                guard let blog = try? Blog.lookup(withID: siteId, in: context),
                      let token = blog.authToken else {
                    return WpAuthentication.none
                }
                return WpAuthentication.bearer(token: token)
            case let .selfHosted(blogId, _, _, _):
                guard let blog = try? context.existingObject(with: blogId),
                      let username = try? blog.getUsername(),
                      let password = try? blog.getApplicationToken()
                else {
                    return WpAuthentication.none
                }

                return WpAuthentication(username: username, password: password)
            }
        }
    }

    func auth() -> WordPressAPIInternal.WpAuthentication {
        lock.lock()
        defer {
            lock.unlock()
        }

        return self.authentication
    }
}

private class AppNotifier: @unchecked Sendable, WpAppNotifier {
    weak var api: WordPressAPI?

    func requestedWithInvalidAuthentication() async {
        NotificationCenter.default.post(name: WordPressClient.requestedWithInvalidAuthenticationNotification, object: api)
    }
}
