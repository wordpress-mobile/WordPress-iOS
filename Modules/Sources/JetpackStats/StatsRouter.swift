import SwiftUI
import UIKit

public struct StatsRouter: Sendable {
    public weak var navigationController: UINavigationController?

    public init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    @MainActor
    func navigate<Content: View>(to view: Content) {
        let viewController = UIHostingController(rootView: view)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Environment Key

private struct StatsRouterKey: EnvironmentKey {
    static let defaultValue = StatsRouter()
}

extension EnvironmentValues {
    var router: StatsRouter {
        get { self[StatsRouterKey.self] }
        set { self[StatsRouterKey.self] = newValue }
    }
}
