import Foundation
import AsyncImageKit
import AVFoundation
import WordPressAPI
import WordPressAPIInternal
import Combine

actor WordPressDotComClient: MediaHostProtocol {

    private let authProvider: AutoUpdatingWPComAuthenticationProvider
    private let delegate: WpApiClientDelegate
    let api: WPComApiClient

    init() {
        let session = URLSession(configuration: .ephemeral)

        self.authProvider = AutoUpdatingWPComAuthenticationProvider(coreDataStack: ContextManager.shared)
        self.delegate = WpApiClientDelegate(
            authProvider: .dynamic(dynamicAuthenticationProvider: self.authProvider),
            requestExecutor: WpRequestExecutor(urlSession: session),
            middlewarePipeline: WpApiMiddlewarePipeline(middlewares: []),
            appNotifier: WpComNotifier()
        )

        self.api = WPComApiClient(delegate: delegate)
    }

    func authenticatedRequest(for url: URL) async throws -> URLRequest {
        self.authProvider.authorize(URLRequest(url: url))
    }

    func authenticatedAsset(for url: URL) async throws -> AVURLAsset {
        self.authProvider.authorize(AVURLAsset(url: url))
    }
}

final class AutoUpdatingWPComAuthenticationProvider: @unchecked Sendable, WpDynamicAuthenticationProvider {
    private let lock = NSLock()
    private var authentication: WpAuthentication

    private let coreDataStack: CoreDataStack

    private var cancellable: AnyCancellable?

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        self.authentication = Self.readAuthentication(on: coreDataStack)

        self.cancellable = NotificationCenter.default.publisher(for: SelfHostedSiteAuthenticator.applicationPasswordUpdated).sink { [weak self] _ in
            self?.update()
        }
    }

    @discardableResult
    func update() -> WpAuthentication {

        let authentication = Self.readAuthentication(on: coreDataStack)

        // This line does not require `self.lock`. Putting it behind the `self.lock` may lead to dead lock, because
        // `coreDataStack.performQuery` also aquire locks.

        self.lock.lock()
        defer {
            self.lock.unlock()
        }

        self.authentication = authentication

        return authentication
    }

    private var authorizationHeaderValue: String? {
        switch self.authentication {
        case .authorizationHeader(let headerValue):
            headerValue
        case .bearer(let token):
            "Bearer \(token)"
        default: nil
        }
    }

    func authorize(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request

        // Don't authorize requests for other domains
        guard request.url?.host() == "public-api.wordpress.com" else {
            return request
        }

        mutableRequest.setValue(self.authorizationHeaderValue, forHTTPHeaderField: "Authorization")

        return mutableRequest
    }

    func authorize(_ asset: AVURLAsset) -> AVURLAsset {

        // Don't authorize requests for other domains
        guard asset.url.host() == "public-api.wordpress.com" else {
            return asset
        }

        guard let headerValue = self.authorizationHeaderValue else {
            return asset
        }

        let headers: [String: String] = ["Authorization": headerValue]

        return AVURLAsset(url: asset.url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ])
    }

    private static func readAuthentication(on stack: CoreDataStack) -> WpAuthentication {
        do {
            guard let authToken = try stack.performQuery({
                try WPAccount.lookupDefaultWordPressComAccountToken(in: $0)
            })
            else {
                return .none
            }

            return .bearer(token: authToken)
        } catch {
//            wpAssertionFailure("Failed to read auth token")
            return .none
        }
    }

    func auth() -> WordPressAPIInternal.WpAuthentication {
        lock.lock()
        defer {
            lock.unlock()
        }

        return self.authentication
    }

    func refresh() async -> Bool {
        return false // WP.com doesn't support programmatically refreshing the auth token
    }
}

final class WpComNotifier: WpAppNotifier {
    static let notificationName = Notification.Name("wpcom-invalid-authentication-provided")

    func requestedWithInvalidAuthentication(requestUrl: String) async {
        NotificationCenter.default.post(name: Self.notificationName, object: nil)
    }
}
