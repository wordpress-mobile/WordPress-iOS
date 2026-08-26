import UIKit
import WordPressComments
import WordPressCore
import WordPressData

/// Single source of truth for routing into Comments v2. Both legacy entry
/// points (BlogDetailsViewController.showComments and the dashboard quick
/// action) call this helper. Returns nil unless the feature flag is on AND
/// the site is self-hosted with an application password (the only site type
/// M1 supports; WP.com and Jetpack sites are a follow-up project), so the
/// caller's legacy fall-through is a one-liner.
///
/// Known M1 limitation: users without the edit_posts capability get a 401
/// from the list's status queries and see the screen's error state. The
/// legacy screen is equally broken for them (XML-RPC requires
/// moderate_comments), so this is not a regression; capability handling
/// arrives with M2's /users/me fetch.
@MainActor
enum CommentsRouting {
    static func makeViewController(for blog: Blog) -> UIViewController? {
        guard FeatureFlag.commentsV2.enabled,
            let site = try? WordPressSite(blog: blog),
            case .selfHosted = site.flavor
        else {
            return nil
        }
        let client = WordPressClientFactory.shared.instance(for: site)
        return CommentsHostingController.make(client: client)
    }
}
