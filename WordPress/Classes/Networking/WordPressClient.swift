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

    /// Identifies a cached client by both the site and the transport it was built for.
    ///
    /// A site's transport changes underneath us: a WordPress.com site starts out proxied through
    /// the WP.com REST API and switches to addressing its own API root once an application
    /// password is created. The two speak to different API roots, whose discovery documents key
    /// routes differently — the proxy namespaces everything under `/sites/{id}/`. Caching on the
    /// blog alone kept serving a client whose cached API root no longer matched the transport its
    /// callers were reasoning about, so route lookups silently missed.
    ///
    /// The transport's credentials are part of the identity, not just which case it is: rotating
    /// an application password or refreshing the site's REST API root changes where requests go
    /// and how they authenticate while staying `.direct`, and a client built for the superseded
    /// credentials would keep being served.
    private struct CacheKey: Hashable {
        let blogId: TaggedManagedObjectID<Blog>
        let transport: WordPressSite.Transport

        init(site: WordPressSite) {
            self.blogId = site.blogId
            self.transport = site.transport
        }
    }

    private let instances = OSAllocatedUnfairLock<[CacheKey: WordPressClient]>(initialState: [:])
    private init() {}

    public func instance(for site: WordPressSite) -> WordPressClient {
        let key = CacheKey(site: site)
        return instances.withLock { dict in
            if let client = dict[key] {
                return client
            }

            let client = WordPressClient(site: site)
            // Drop any client built for this site's previous transport; its cached API root
            // describes a different root than the one this site now uses.
            dict = dict.filter { $0.key.blogId != key.blogId }
            dict[key] = client
            return client
        }
    }

    public func evictInstance(for blogID: TaggedManagedObjectID<Blog>) {
        instances.withLock { dict in
            dict = dict.filter { $0.key.blogId != blogID }
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

    fileprivate init(site: WordPressSite) {
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
            dynamicAuthenticationProvider: AutoUpdateAuthenticationProvider(
                site: site,
                coreDataStack: ContextManager.shared
            )
        )
        let siteInfo: SiteInfo
        switch site.transport {
        case let .direct(credentials):
            siteInfo = .selfHosted(siteUrl: try! ParsedUrl.from(url: site.siteURL), apiRoot: credentials.apiRootURL)
        case let .dotComProxy(siteId, _):
            siteInfo = .wordPressCom(siteId: WpComSiteId(siteId))
        }
        let api = WordPressAPI(
            urlSession: session,
            notifyingDelegate: PulseNetworkLogger.shared,
            siteInfo: siteInfo,
            authenticationProvider: provider,
            appNotifier: notifier,
        )
        self.init(api: api, siteURL: site.siteURL)
    }

    func installJetpack() async throws -> PluginWithEditContext {
        try await self.api.plugins
            .create(
                params: PluginCreateParams(
                    slug: "InstallJetpack",
                    status: .active
                )
            )
            .data
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
        self.authentication =
            switch site.transport {
            case let .direct(credentials):
                .init(username: credentials.username, password: credentials.token)
            case let .dotComProxy(_, oAuthToken):
                .bearer(token: oAuthToken)
            }

        self.cancellable = NotificationCenter.default
            .publisher(for: SelfHostedSiteAuthenticator.applicationPasswordUpdated)
            .sink { [weak self] _ in
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
        let blogId = site.blogId

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
        NotificationCenter.default.post(
            name: WordPressClient.requestedWithInvalidAuthenticationNotification,
            object: site.blogId
        )
    }
}

private extension WordPressSite {
    func authentication(in context: NSManagedObjectContext) -> WpAuthentication {
        // The transport (and thus the credential kind) is fixed when the
        // client is created, so refreshed credentials must match it.
        switch self.transport {
        case .direct:
            guard let blog = try? context.existingObject(with: blogId),
                let username = try? blog.getUsername(),
                let password = try? blog.getApplicationToken()
            else {
                return WpAuthentication.none
            }

            return WpAuthentication(username: username, password: password)
        case .dotComProxy:
            guard let blog = try? context.existingObject(with: blogId),
                let token = blog.account?.authToken
            else {
                return WpAuthentication.none
            }
            return WpAuthentication.bearer(token: token)
        }
    }
}
