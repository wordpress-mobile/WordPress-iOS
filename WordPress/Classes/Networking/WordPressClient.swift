import os
import Foundation
import Combine
import WordPressAPI
import WordPressAPIInternal // Required for `WpAuthenticationProvider`
import WordPressCore
import WordPressData
import WordPressShared

public final class WordPressClientFactory: Sendable {
    public static let shared = WordPressClientFactory()

    private let instances = OSAllocatedUnfairLock<[WordPressSite: WordPressClient]>(initialState: [:])
    private init() {}

    public func instance(for site: WordPressSite) -> WordPressClient {
        instances.withLock { dict in
            if let client = dict[site] {
                return client
            } else {
                let client = WordPressClient(site: site)
                dict[site] = client
                return client
            }
        }
    }

    public func reset() {
        instances.withLock { dict in
            dict.removeAll()
        }
    }
}

extension WordPressClient {
    static var requestedWithInvalidAuthenticationNotification: Foundation.Notification.Name {
        .init("WordPressClient.requestedWithInvalidAuthenticationNotification")
    }

    fileprivate convenience init(site: WordPressSite) {
        // Currently, the app supports both account passwords and application passwords.
        // When a site is initially signed in with an account password, WordPress login cookies are stored
        // in `URLSession.shared`. After switching the site to application password authentication,
        // the stored cookies may interfere with application-password authentication, resulting in 401
        // errors from the REST API.
        //
        // To avoid this issue, we'll use an ephemeral URLSession for now (which stores cookies in memory
        // rather than using the shared one on disk).
        let session = URLSession(configuration: .ephemeral)

        let notifier = AppNotifier(site: site, coreDataStack: ContextManager.shared)
        let provider = WpAuthenticationProvider.dynamic(
            dynamicAuthenticationProvider: AutoUpdateAuthenticationProvider(site: site, coreDataStack: ContextManager.shared)
        )
        let siteURL: URL
        let apiRootURL: ParsedUrl
        let resolver: ApiUrlResolver
        switch site {
        case let .dotCom(url, siteId, _):
            siteURL = url
            apiRootURL = try! ParsedUrl.parse(input: AppEnvironment.current.wordPressComApiBase.absoluteString)
            resolver = WpComDotOrgApiUrlResolver(siteId: "\(siteId)", baseUrl: .custom(apiRootURL))
        case let .selfHosted(_, url, apiRoot, _, _):
            siteURL = url
            apiRootURL = apiRoot
            resolver = WpOrgSiteApiUrlResolver(apiRootUrl: apiRoot)
        }
        let api = WordPressAPI(
            urlSession: session,
            notifyingDelegate: PulseNetworkLogger(),
            apiUrlResolver: resolver,
            authenticationProvider: provider,
            appNotifier: notifier,
        )
        self.init(api: api, siteURL: siteURL)
    }

    func installJetpack() async throws -> PluginWithEditContext {
        try await self.api.plugins.create(params: PluginCreateParams(
            slug: "InstallJetpack",
            status: .active
        )).data
    }
}

// TODO: Remove this
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
        case let .dotCom(_, _, authToken):
            .bearer(token: authToken)
        case let .selfHosted(_, _, _, username, authToken):
            .init(username: username, password: authToken)
        }

        self.cancellable = NotificationCenter.default.publisher(for: SelfHostedSiteAuthenticator.applicationPasswordUpdated).sink { [weak self] _ in
            self?.update()
        }
    }

    @discardableResult
    func update() -> WpAuthentication {
        // This line does not require `self.lock`. Putting it behind the `self.lock` may lead to dead lock, because
        // `coreDataStack.performQuery` also aquire locks.
        let authentication = coreDataStack.performQuery(site.authentication(in:))

        self.lock.lock()
        defer {
            self.lock.unlock()
        }

        self.authentication = authentication
        return authentication
    }

    func auth() -> WpAuthentication {
        lock.lock()
        defer {
            lock.unlock()
        }

        return self.authentication
    }

    func refresh() async -> Bool {
        guard let blogId = site.blogId(in: coreDataStack) else { return false }

        do {
            DDLogInfo("Create a new application password")
            try await ApplicationPasswordRepository.shared.createPasswordIfNeeded(for: blogId)
        } catch {
            DDLogInfo("Failed to create a new application password: \(error)")
            return false
        }

        let current = auth()
        let newAuth = update()
        return newAuth != .none && newAuth != current
    }
}

private class AppNotifier: @unchecked Sendable, WpAppNotifier {
    let site: WordPressSite
    let coreDataStack: CoreDataStack

    init(site: WordPressSite, coreDataStack: CoreDataStack) {
        self.site = site
        self.coreDataStack = coreDataStack
    }

    func requestedWithInvalidAuthentication(requestUrl: String) async {
        let blogId = site.blogId(in: coreDataStack)
        NotificationCenter.default.post(name: WordPressClient.requestedWithInvalidAuthenticationNotification, object: blogId)
    }
}

private extension WordPressSite {
    func authentication(in context: NSManagedObjectContext) -> WpAuthentication {
        switch self {
        case let .dotCom(_, siteId, _):
            guard let blog = try? Blog.lookup(withID: siteId, in: context),
                  let token = blog.authToken else {
                return WpAuthentication.none
            }
            return WpAuthentication.bearer(token: token)
        case let .selfHosted(blogId, _, _, _, _):
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
