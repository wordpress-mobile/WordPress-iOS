import SwiftUI
import UIKit
import SafariServices

@MainActor
public protocol StatsRouterScreenFactory: AnyObject {
    func makeLikesListViewController(siteID: Int, postID: Int, totalLikes: Int) -> UIViewController
    func makeCommentsListViewController(siteID: Int, postID: Int) -> UIViewController
}

public final class StatsRouter: @unchecked Sendable {
    @MainActor
    var navigationController: UINavigationController? {
        let vc = viewController ?? findTopViewController()
        return (vc as? UINavigationController) ?? vc?.navigationController
    }

    public weak var viewController: UIViewController?

    let factory: StatsRouterScreenFactory

    public init(viewController: UIViewController? = nil, factory: StatsRouterScreenFactory) {
        self.viewController = viewController
        self.factory = factory
    }

    @MainActor
    private func findTopViewController() -> UIViewController? {
        guard let window = UIApplication.shared.mainWindow else {
            return nil
        }
        var topController = window.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
    }

    @MainActor
    func navigate<Content: View>(to view: Content, title: String? = nil) {
        let viewController = UIHostingController(rootView: view)
        if let title {
            // This ensures that it gets rendered instantly on navigation
            viewController.title = title
        }
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

    @MainActor
    func openURL(_ url: URL) {
        // Open URL in in-app Safari
        let safariViewController = SFSafariViewController(url: url)
        let vc = viewController ?? findTopViewController()
        vc?.present(safariViewController, animated: true)
    }
}

private extension UIApplication {
    @objc var mainWindow: UIWindow? {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
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
