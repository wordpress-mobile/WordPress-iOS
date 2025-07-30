import UIKit
import SwiftUI
import JetpackStats
import WordPressKit
import WordPressShared
import Gravatar
import BuildSettingsKit

/// A UIViewController wrapper for the new SwiftUI StatsMainView
class StatsHostingViewController: UIViewController {
    static func makeNewTrafficViewController(blog: Blog? = nil, parentViewController: UIViewController, isDemo: Bool = false) -> UIViewController? {
        let context: StatsContext
        if isDemo {
            context = StatsContext.demo
        } else {
            guard let blog, let blogContext = StatsContext(blog: blog) else {
                return nil
            }
            context = blogContext
        }

        let statsView = StatsMainView(
            context: context,
            router: StatsRouter(viewController: parentViewController),
            showTabs: false
        )
        let hostingController = SafeAreaHostingController(rootView: statsView)

        return hostingController
    }

    static func makeStatsViewController(for blog: Blog) -> UIViewController {
        let statsVC = StatsViewController()
        statsVC.blog = blog
        statsVC.hidesBottomBarWhenPushed = true
        statsVC.navigationItem.largeTitleDisplayMode = .never
        return statsVC
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

        // Configure analytics tracker
        self.tracker = WPAnalyticsStatsTracker()
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

/// A custom UIHostingController that properly handles safe area insets when embedded in containers like UIPageViewController
private class SafeAreaHostingController<Content: View>: UIHostingController<Content> {
    private var safeAreaObservation: NSKeyValueObservation?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupSafeAreaObservation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        safeAreaObservation?.invalidate()
        safeAreaObservation = nil
    }

    private func setupSafeAreaObservation() {
        // Find the root view controller (should be SiteStatsDashboardViewController or its parent)
        var rootViewController: UIViewController? = self
        while let parent = rootViewController?.parent {
            rootViewController = parent
        }

        guard let rootView = rootViewController?.view else { return }

        // Observe changes to the root view's safe area insets
        safeAreaObservation = rootView.observe(\.safeAreaInsets, options: [.initial, .new]) { [weak self] view, _ in
            self?.updateSafeAreaInsets(from: view)
        }
    }

    private func updateSafeAreaInsets(from rootView: UIView) {
        // Apply the root view's bottom safe area inset
        let bottomInset = rootView.safeAreaInsets.bottom
        if additionalSafeAreaInsets.bottom != bottomInset {
            additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: min(20, bottomInset), right: 0)
        }
    }
}

// MARK: - WPAnalyticsStatsTracker

/// A StatsTracker implementation that bridges JetpackStats analytics to WPAnalytics
private final class WPAnalyticsStatsTracker: StatsTracker {
    func send(_ event: StatsEvent, properties: [String: String]) {
        // Convert String properties to [AnyHashable: Any]
        let wpProperties: [AnyHashable: Any] = properties.reduce(into: [:]) { result, pair in
            result[pair.key] = pair.value
        }

        WPAnalytics.track(event.wpEvent, properties: wpProperties)
    }
}
