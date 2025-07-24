import SwiftUI
import UIKit

public struct StatsRouter: Sendable {
    public weak var navigationController: UINavigationController?
    
    public init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    @MainActor
    func navigate(to destination: StatsDestination) {
        guard let navigationController else { return }
        
        let viewController: UIViewController
        
        switch destination {
        case .postDetails(let post, let dateRange):
            let view = PostStatsDetailsView(post: post, dateRange: dateRange)
            viewController = UIHostingController(rootView: view)
        }
        
        navigationController.pushViewController(viewController, animated: true)
    }
}

enum StatsDestination {
    case postDetails(post: TopListData.Post, dateRange: StatsDateRange)
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
