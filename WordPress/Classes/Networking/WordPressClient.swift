import Foundation
import Combine
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressShared

enum WordPressSite {
    case dotCom(authToken: String)
    case selfHosted(blogId: TaggedManagedObjectID<Blog>, apiRootURL: ParsedUrl, username: String, authToken: String)

    init(blog: Blog) throws {
        if let account = blog.account {
            let authToken = try account.authToken ?? WPAccount.token(forUsername: account.username)
            self = .dotCom(authToken: authToken)
        } else {
            let url = try blog.restApiRootURL ?? blog.getUrl().appending(path: "wp-json").absoluteString
            let apiRootURL = try ParsedUrl.parse(input: url)
            self = .selfHosted(blogId: TaggedManagedObjectID(blog), apiRootURL: apiRootURL, username: try blog.getUsername(), authToken: try blog.getApplicationToken())
        }
    }
}

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

        switch site {
        case let .dotCom(authToken):
            let apiRootURL = try! ParsedUrl.parse(input: "https://public-api.wordpress.com")
            let api = WordPressAPI(urlSession: session, apiRootUrl: apiRootURL, authentication: .bearer(token: authToken))
            self.init(api: api, rootUrl: apiRootURL)
        case let .selfHosted(blogId, apiRootURL, username, authToken):
            let provider = AutoUpdateAuthenticationProvider(
                authentication: .init(username: username, password: authToken),
                blogId: blogId,
                coreDataStack: ContextManager.shared
            )
            let notifier = AppNotifier()
            let api = WordPressAPI(urlSession: session, apiRootUrl: apiRootURL, authenticationProvider: .dynamic(dynamicAuthenticationProvider: provider), appNotifier: notifier)
            notifier.api = api
            self.init(api: api, rootUrl: apiRootURL)
        }
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
    private var authentication: WpAuthentication
    private var cancellable: AnyCancellable?

    init(authentication: WpAuthentication, blogId: TaggedManagedObjectID<Blog>, coreDataStack: CoreDataStack) {
        self.authentication = authentication
        self.cancellable = NotificationCenter.default.publisher(for: SelfHostedSiteAuthenticator.applicationPasswordUpdated).sink { [weak self] _ in
            guard let self else { return }

            self.lock.lock()
            defer {
                self.lock.unlock()
            }

            self.authentication = coreDataStack.performQuery { context in
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
