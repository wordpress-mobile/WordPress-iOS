import SwiftUI
import UIKit

public protocol StatsRouterDelegate: AnyObject {
    func makeLikesListViewController(siteID: Int, postID: Int, totalLikes: Int) -> UIViewController?
    func makeCommentsListViewController(siteID: Int, postID: Int) -> UIViewController?
}

public final class StatsRouter: @unchecked Sendable {
    public weak var navigationController: UINavigationController?
    private weak var _delegate: StatsRouterDelegate?

    public var delegate: StatsRouterDelegate? {
        get { _delegate }
        set { _delegate = newValue }
    }

    public init(navigationController: UINavigationController? = nil, delegate: StatsRouterDelegate? = nil) {
        self.navigationController = navigationController
        self._delegate = delegate
    }

    @MainActor
    public func navigate<Content: View>(to view: Content) {
        let viewController = UIHostingController(rootView: view)
        navigationController?.pushViewController(viewController, animated: true)
    }

    @MainActor
    public func navigateToLikesList(siteID: Int, postID: Int, totalLikes: Int) {
        guard let viewController = delegate?.makeLikesListViewController(siteID: siteID, postID: postID, totalLikes: totalLikes) else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    @MainActor
    public func navigateToCommentsList(siteID: Int, postID: Int) {
        guard let viewController = delegate?.makeCommentsListViewController(siteID: siteID, postID: postID) else {
            return
        }
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
