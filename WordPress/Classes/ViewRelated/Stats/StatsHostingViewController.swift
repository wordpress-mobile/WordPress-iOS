import UIKit
import SwiftUI
import JetpackStats
import WordPressKit
import WordPressShared
import Gravatar
import BuildSettingsKit

/// A UIViewController wrapper for the new SwiftUI StatsMainView
class StatsHostingViewController: UIViewController {
    static func makeNewTrafficViewController(blog: Blog, parentViewController: UIViewController) -> UIViewController? {
        guard let context = StatsContext(blog: blog) else {
            return nil
        }
        let statsView = StatsMainView(
            context: context,
            router: StatsRouter(viewController: parentViewController),
            showTabs: false
        )
        return UIHostingController(rootView: statsView)
    }

    static func makeStatsViewController(for blog: Blog) -> UIViewController {
        let statsVC = StatsViewController()
        statsVC.blog = blog
        statsVC.hidesBottomBarWhenPushed = true
        statsVC.navigationItem.largeTitleDisplayMode = .never
        return statsVC
    }

    private func setupStatsView() {

//        if isUsingMockService {
//            // For mock service, we need to use the internal initializer
//            // Since we can't access it directly, we'll use the demo context
//            context = StatsContext.demo
//        }
//
//        let statsView = StatsMainView(context: context, router: StatsRouter(viewController: self), showTabs: showTabs)
//        let hostingController = UIHostingController(rootView: AnyView(statsView))
//
//        addChild(hostingController)
//        view.addSubview(hostingController.view)
//        hostingController.view.pinEdges()
//        hostingController.didMove(toParent: self)
//
//        self.hostingController = hostingController
    }

    private func setupNavigationBar() {
        // Add menu button with ellipsis
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: createMenu()
        )
        navigationItem.rightBarButtonItem = menuButton
    }

    private func createMenu() -> UIMenu {
        var actions: [UIMenuElement] = []

        // Toggle data source (only in debug builds)
//        if BuildConfiguration.current == .debug {
//            let toggleDataSource = UIAction(
//                title: isUsingMockService ? "Use Real Data" : "Use Mock Data",
//                image: UIImage(systemName: "arrow.triangle.2.circlepath")
//            ) { [weak self] _ in
//                self?.toggleServiceType()
//            }
//            actions.append(toggleDataSource)
//        }

        return UIMenu(children: actions)
    }

    private func toggleServiceType() {
//        isUsingMockService.toggle()
//
//        // Remove existing hosting controller
//        hostingController?.willMove(toParent: nil)
//        hostingController?.view.removeFromSuperview()
//        hostingController?.removeFromParent()
//        hostingController = nil
//
//        // Recreate with new service
//        setupStatsView()
//
//        // Update menu
//        updateNavigationMenu()
//
//        // Show notice indicating the change
//        let message = isUsingMockService ? "Using mock data" : "Using real data"
//        Notice(title: message).post()
    }
}

extension StatsContext {
    init?(blog: Blog) {
        guard let siteID = blog.dotComID?.intValue,
              let api = blog.account?.wordPressComRestApi else {
            wpAssertionFailure("required context missing")
            return nil
        }
        self.init(
            timeZone: blog.timeZone ?? .current,
            siteID: siteID,
            api: api
        )

        // Configure avatar preprocessing using Gravatar
        self.preprocessAvatar = { url, size in
            // Use AvatarURL from Gravatar to update the URL to the requested pixel size
            guard let avatarURL = AvatarURL(url: url) else {
                return url
            }
            let options = AvatarQueryOptions(preferredSize: .points(size))
            return avatarURL.replacing(options: options)?.url ?? url
        }
    }
}

extension StatsRouter {
    @MainActor
    convenience init(viewController: UIViewController) {
        self.init(
            viewController: viewController,
            factory: JetpackAppStatsRouterScreenFactory()
        )
    }
}

/// Shared router implementation for Jetpack app stats navigation
private final class JetpackAppStatsRouterScreenFactory: StatsRouterScreenFactory {
    func makeLikesListViewController(siteID: Int, postID: Int, totalLikes: Int) -> UIViewController {
        StatsLikesListViewController(
            siteID: siteID as NSNumber,
            postID: NSNumber(value: postID),
            totalLikes: totalLikes
        )
    }

    func makeCommentsListViewController(siteID: Int, postID: Int) -> UIViewController {
        ReaderCommentsViewController(
            postID: NSNumber(value: postID),
            siteID: siteID as NSNumber
        )
    }
}
