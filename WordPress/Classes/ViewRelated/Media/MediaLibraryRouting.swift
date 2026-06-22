import UIKit
import WordPressCore
import WordPressData
import WordPressMediaLibrary

/// Single source of truth for routing into the V2 Media Library. Both V1
/// entry points (BlogDetailsViewController.showMediaLibrary and
/// DashboardQuickActionsCardCell .media case) call this helper. Returns nil
/// when either the FeatureFlag is off or the site can't construct a
/// WordPressSite, so the caller's V1 fall-through is a one-liner.
@MainActor
enum MediaLibraryRouting {
    static func makeViewController(
        for blog: Blog,
        baseAnalyticsProperties: [String: Any]
    ) -> UIViewController? {
        guard FeatureFlag.mediaLibraryV2.enabled,
            let site = try? WordPressSite(blog: blog)
        else {
            return nil
        }
        let client = WordPressClientFactory.shared.instance(for: site)

        // Explicit two-step instead of `.merging(...)`. Reason:
        // `baseAnalyticsProperties` is `[String: Any]`; a `["is_v2": "1"]`
        // literal can infer as `[String: String]` and fail to type-check
        // against the merging overload. Explicit form avoids the gamble.
        var properties = baseAnalyticsProperties
        properties["is_v2"] = "1"
        let tracker = MediaTrackerAdapter(blog: blog, baseProperties: properties)

        return MediaLibraryHostingController.make(client: client, tracker: tracker)
    }
}
