import UIKit
import SwiftUI
import JetpackStats
import WordPressKit
import WordPressShared
import WordPressData
import Gravatar
import BuildSettingsKit

/// A UIViewController wrapper for the new SwiftUI StatsMainView
class StatsHostingViewController: UIViewController {
    static func makeNewTrafficViewController(
        blog: Blog? = nil,
        parentViewController: UIViewController,
        isDemo: Bool = false
    ) -> UIViewController? {
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
        return UIHostingController(rootView: statsView)
    }

    static func makeStatsViewController(for blog: Blog) -> UIViewController {
        let statsVC = StatsViewController()
        statsVC.blog = blog
        statsVC.hidesBottomBarWhenPushed = true
        statsVC.navigationItem.largeTitleDisplayMode = .never
        return statsVC
    }

    static func makeAdsViewController(blog: Blog, parentViewController: UIViewController) -> UIViewController? {
        guard let context = StatsContext(blog: blog) else {
            return nil
        }

        let adsView = AdsTabView(
            context: context,
            router: StatsRouter(viewController: parentViewController)
        )
        let hostingController = UIHostingController(rootView: adsView)
        hostingController.view.backgroundColor = .systemBackground
        return hostingController
    }
}

extension StatsContext {
    init?(blog: Blog) {
        guard let siteID = blog.dotComID?.intValue,
            let api = blog.account?.wordPressComRestApi
        else {
            wpAssertionFailure("required context missing")
            return nil
        }
        self.init(
            timeZone: blog.timeZone ?? .current,
            siteID: siteID,
            api: api,
            postLikesStore: StatsPostLikesStore(siteID: Int64(siteID))
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

        self.tracker = WPAnalyticsStatsTracker(blogProperties: blog.analyticsProperties)

        self.upgradeURL = Self.makeUpgradeURL(for: blog)
    }

    /// A context for embedding the Today card on the My Site dashboard: the same
    /// as the Stats-screen context but with NO analytics tracker, so the
    /// embedded card never feeds the Stats-screen funnels (the dashboard fires
    /// its own card-shown/tapped events, matching the legacy card).
    ///
    /// It reuses `StatsContext(blog:)`, which asserts on failure. That is an
    /// accepted, deliberate trade-off: `DashboardCard.newStatsActive` only
    /// selects this card for WP.com-connected sites with a non-empty auth token,
    /// and `WPAccount.wordPressComRestApi` is non-nil whenever the token is
    /// non-empty, so construction succeeds in practice. The assertion is
    /// reachable only if a logout races the synchronous, main-thread
    /// parse -> configure path, which is effectively unreachable. On that
    /// theoretical failure the cell renders the empty state and falls back to
    /// the legacy card. See the cross-agent code review discussion.
    static func dashboard(blog: Blog) -> StatsContext? {
        guard var context = StatsContext(blog: blog) else {
            return nil
        }
        context.tracker = nil
        return context
    }

    private static func makeUpgradeURL(for blog: Blog) -> URL {
        if blog.isHostedAtWPcom {
            return URL(string: "https://wordpress.com/pricing/")!
        } else {
            return URL(string: "https://cloud.jetpack.com/pricing")!
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
        LikesListHostViewController(
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

// MARK: - WPAnalyticsStatsTracker

/// A StatsTracker implementation that bridges JetpackStats analytics to WPAnalytics
private final class WPAnalyticsStatsTracker: StatsTracker {
    private let blogProperties: BlogAnalyticsProperties

    init(blogProperties: BlogAnalyticsProperties) {
        self.blogProperties = blogProperties
    }

    func send(_ event: StatsEvent, properties: [String: String]) {
        // Convert String properties to [AnyHashable: Any]
        let wpProperties: [AnyHashable: Any] = properties.reduce(into: [:]) { result, pair in
            result[pair.key] = pair.value
        }

        // Every Stats event is scoped to the site being viewed, so attach its blog_id and site_type.
        WPAnalytics.track(event.wpEvent, properties: wpProperties, blogProperties: blogProperties)
    }
}
