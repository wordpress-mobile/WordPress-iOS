import SwiftUI
import UIKit

@MainActor
public protocol StatsRouterScreenFactory: AnyObject {
    func makeLikesListViewController(siteID: Int, postID: Int, totalLikes: Int) -> UIViewController
    func makeCommentsListViewController(siteID: Int, postID: Int) -> UIViewController
}

public final class StatsRouter: @unchecked Sendable {
    @MainActor
    var navigationController: UINavigationController? {
        (viewController as? UINavigationController) ?? viewController?.navigationController
    }

    public weak var viewController: UIViewController?

    let factory: StatsRouterScreenFactory

    public init(viewController: UIViewController? = nil, factory: StatsRouterScreenFactory) {
        self.viewController = viewController
        self.factory = factory
    }

    @MainActor
    func navigate<Content: View>(to view: Content) {
        let viewController = UIHostingController(rootView: view)
        navigationController?.pushViewController(viewController, animated: true)
    }

    @MainActor
    func navigateToLikesList(siteID: Int, postID: Int, totalLikes: Int) {
        let likesVC = factory.makeLikesListViewController(siteID: siteID, postID: postID, totalLikes: totalLikes)
        navigationController?.pushViewController(likesVC, animated: true)
    }

    @MainActor
    func navigateToCommentsList(siteID: Int, postID: Int) {
        let commentsVC = factory.makeCommentsListViewController(siteID: siteID, postID: postID)
        navigationController?.pushViewController(commentsVC, animated: true)
    }
}

class MockStatsRouterScreenFactory: StatsRouterScreenFactory {
    func makeCommentsListViewController(siteID: Int, postID: Int) -> UIViewController {
        UIHostingController(rootView: Text(Strings.Errors.generic))
    }

    func makeLikesListViewController(siteID: Int, postID: Int, totalLikes: Int) -> UIViewController {
        UIHostingController(rootView: Text(Strings.Errors.generic))
    }
}

// MARK: - Environment Key

private struct StatsRouterKey: EnvironmentKey {
    static let defaultValue = StatsRouter(factory: MockStatsRouterScreenFactory())
}

extension EnvironmentValues {
    var router: StatsRouter {
        get { self[StatsRouterKey.self] }
        set { self[StatsRouterKey.self] = newValue }
    }
}
