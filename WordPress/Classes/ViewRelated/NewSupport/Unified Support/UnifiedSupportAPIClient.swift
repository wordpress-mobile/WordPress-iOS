import Foundation
import AsyncImageKit
import AVFoundation
import Combine
import WordPressAPI
import WordPressAPIInternal
import WordPressData

/// A WordPress.com API client for the unified support flow.
///
/// Unlike `WordPressDotComClient`, it picks up a new token when the user logs in to a different WordPress.com account,
/// and it waits longer for responses because the AI Assistant can take a while to answer.
actor UnifiedSupportAPIClient: MediaHostProtocol {

    let api: WPComApiClient

    private let authProvider: UnifiedSupportAuthenticationProvider
    private let delegate: WpApiClientDelegate

    init(coreDataStack: CoreDataStack = ContextManager.shared, requestTimeout: TimeInterval = 120) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = requestTimeout

        self.authProvider = UnifiedSupportAuthenticationProvider(coreDataStack: coreDataStack)
        self.delegate = WpApiClientDelegate(
            authProvider: .dynamic(dynamicAuthenticationProvider: authProvider),
            requestExecutor: WpRequestExecutor(urlSession: URLSession(configuration: configuration)),
            middlewarePipeline: WpApiMiddlewarePipeline(middlewares: [
                WpComTrafficDebugger()
            ]),
            appNotifier: WpComNotifier(),
            languageProvider: WPComDeviceLanguageProvider()
        )
        self.api = WPComApiClient(delegate: delegate)
    }

    func authenticatedRequest(for url: URL) async throws -> URLRequest {
        authProvider.authorize(URLRequest(url: url))
    }

    func authenticatedAsset(for url: URL) async throws -> AVURLAsset {
        authProvider.authorize(AVURLAsset(url: url))
    }
}

/// Authenticates requests with the token of the default WordPress.com account.
final class UnifiedSupportAuthenticationProvider: WpDynamicAuthenticationProvider, @unchecked Sendable {

    private let coreDataStack: CoreDataStack
    private let lock = NSLock()
    private var authentication: WpAuthentication
    private var cancellable: AnyCancellable?

    init(coreDataStack: CoreDataStack, notificationCenter: NotificationCenter = .default) {
        self.coreDataStack = coreDataStack
        self.authentication = Self.readAuthentication(from: coreDataStack)

        self.cancellable =
            notificationCenter
            .publisher(for: .wpAccountDefaultWordPressComAccountChanged)
            .sink { [weak self] _ in
                self?.updateAuthentication()
            }
    }

    func auth() -> WpAuthentication {
        lock.withLock { authentication }
    }

    func refresh() async -> Bool {
        false // WordPress.com doesn't support refreshing the token programmatically
    }

    /// Adds the token to requests for WordPress.com API URLs only, so it never leaks to other hosts.
    func authorize(_ request: URLRequest) -> URLRequest {
        guard request.url?.host() == Self.apiHost, let headerValue = authorizationHeaderValue else {
            return request
        }

        var request = request
        request.setValue(headerValue, forHTTPHeaderField: "Authorization")
        return request
    }

    func authorize(_ asset: AVURLAsset) -> AVURLAsset {
        guard asset.url.host() == Self.apiHost, let headerValue = authorizationHeaderValue else {
            return asset
        }

        return AVURLAsset(
            url: asset.url,
            options: [
                "AVURLAssetHTTPHeaderFieldsKey": ["Authorization": headerValue]
            ]
        )
    }

    private static let apiHost = "public-api.wordpress.com"

    private var authorizationHeaderValue: String? {
        guard case .bearer(let token) = auth() else {
            return nil
        }
        return "Bearer \(token)"
    }

    private func updateAuthentication() {
        // Read the token before taking the lock: the Core Data query takes locks of its own.
        let authentication = Self.readAuthentication(from: coreDataStack)
        lock.withLock {
            self.authentication = authentication
        }
    }

    private static func readAuthentication(from coreDataStack: CoreDataStack) -> WpAuthentication {
        let token = coreDataStack.performQuery { context in
            try? WPAccount.lookupDefaultWordPressComAccountToken(in: context)
        }
        guard let token else {
            return .none
        }
        return .bearer(token: token)
    }
}
