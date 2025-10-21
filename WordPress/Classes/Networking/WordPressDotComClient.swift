import Foundation
import WordPressAPI
import WordPressAPIInternal
import Combine

actor WordPressDotComClient {

    let api: WPComApiClient

    init() {
        let session = URLSession(configuration: .ephemeral)

        let provider = AutoUpdatingWPComAuthenticationProvider(coreDataStack: ContextManager.shared)
        let delegate = WpApiClientDelegate(
            authProvider: .dynamic(dynamicAuthenticationProvider: provider),
            requestExecutor: WpRequestExecutor(urlSession: session),
            middlewarePipeline: WpApiMiddlewarePipeline(middlewares: []),
            appNotifier: WpComNotifier()
        )

        self.api = WPComApiClient(delegate: delegate)
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
