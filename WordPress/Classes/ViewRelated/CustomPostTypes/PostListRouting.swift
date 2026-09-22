import SwiftUI
import UIKit
import WordPressAPI
import WordPressCore
import WordPressData

/// Single source of truth for routing into the wordpress-rs post lists. The
/// site menu (BlogDetailsViewController) and the dashboard entry points (the
/// Posts quick action and the Posts card) all call this helper, so they agree
/// on which list a site gets.
@MainActor
enum PostListRouting {
    /// Returns the wordpress-rs posts list, or nil when the site should keep
    /// the legacy `PostListViewController`.
    static func makePostListViewController(
        for blog: Blog,
        initialTab: CustomPostTab = .all,
        presentingViewController: UIViewController
    ) -> UIViewController? {
        // TODO: Remove before merging. Temporarily routes every WordPress.com-accessible site to the
        // wordpress-rs posts list so the experimental redesign can be tried on those sites, the way
        // Android's `android_wp_rs_wpcom` rollout flag does. iOS has no such routing yet.
        guard blog.usesCustomPostTypeViewsForPostsAndPages || blog.isAccessibleThroughWPCom else {
            return nil
        }
        return makePinnedPostTypeViewController(
            for: blog,
            postType: .posts,
            initialTab: initialTab,
            presentingViewController: presentingViewController
        )
    }

    static func makePinnedPostTypeViewController(
        for blog: Blog,
        postType: PinnedPostType,
        initialTab: CustomPostTab = .all,
        presentingViewController: UIViewController
    ) -> UIViewController {
        let feature = NSLocalizedString(
            "applicationPasswordRequired.feature.customPosts",
            value: "Custom Post Types",
            comment: "Feature name for managing custom post types in the app"
        )
        let makeContent = { [blog, weak presentingViewController] (client: WordPressClient) in
            PinnedPostTypeView<CustomPostTabView>(
                blog: blog,
                service: CustomPostTypeService(client: client, blog: blog),
                postType: postType,
                presentingViewController: presentingViewController
            ) { resolved in
                CustomPostTabView(
                    client: client,
                    service: resolved.wpService,
                    details: resolved.details,
                    blog: blog,
                    initialTab: initialTab,
                    presentingViewController: presentingViewController
                )
            }
        }

        let controller: UIViewController
        // TODO: Remove before merging. WordPress.com-accessible sites don't need an application
        // password: wordpress-rs reaches them through the WP.com REST API with the account's OAuth
        // token, so the application-password gate is skipped for them. Pairs with
        // `makePostListViewController`.
        if blog.isAccessibleThroughWPCom, let site = try? WordPressSite(blog: blog) {
            let client = WordPressClientFactory.shared.instance(for: site)
            controller = UIHostingController(rootView: makeContent(client))
        } else {
            let rootView = ApplicationPasswordRequiredView(
                blog: blog,
                localizedFeatureName: feature,
                source: "custom_post_types",
                presentingViewController: presentingViewController,
                content: makeContent
            )
            controller = UIHostingController(rootView: rootView)
        }
        controller.navigationItem.largeTitleDisplayMode = .never
        return controller
    }
}
