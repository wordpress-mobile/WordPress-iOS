import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressData
import WordPressShared

struct PostTypeClassification {
    /// Slugs of the post types the app lists, sorted ascending.
    let custom: [String]
    /// Slugs of plugin or theme post types the app does not list, sorted ascending.
    let hidden: [String]

    init(_ postTypes: [PostTypeDetailsWithEditContext]) {
        custom = postTypes.filter(\.isCustomPostType).map(\.slug).sorted()
        hidden = postTypes.filter { !$0.isCustomPostType && !Self.isCoreInternal(slug: $0.slug) }.map(\.slug).sorted()
    }

    private static func isCoreInternal(slug: String) -> Bool {
        guard case .custom = postTypeFromString(value: slug) else {
            return true
        }
        // WordPress reserves the `wp_` prefix for core, so core types wordpress-rs does not name still match.
        return slug.hasPrefix("wp_")
    }
}

/// Reports a site's post types once per site per app process.
@MainActor
final class CustomPostTypeUsageTracker {
    static let shared = CustomPostTypeUsageTracker()

    private let coreDataStack: CoreDataStack
    private let track: (WPAnalyticsEvent, [AnyHashable: Any], BlogAnalyticsProperties) -> Void
    private var reportedBlogs: Set<TaggedManagedObjectID<Blog>> = []

    init(
        coreDataStack: CoreDataStack = ContextManager.shared,
        track: @escaping (WPAnalyticsEvent, [AnyHashable: Any], BlogAnalyticsProperties) -> Void = {
            WPAnalytics.track($0, properties: $1, blogProperties: $2)
        }
    ) {
        self.coreDataStack = coreDataStack
        self.track = track
    }

    func hasReported(_ blogID: TaggedManagedObjectID<Blog>) -> Bool {
        reportedBlogs.contains(blogID)
    }

    func report(_ classification: PostTypeClassification, for blogID: TaggedManagedObjectID<Blog>) {
        guard
            !reportedBlogs.contains(blogID),
            let blog = try? coreDataStack.mainContext.existingObject(with: blogID)
        else {
            return
        }
        reportedBlogs.insert(blogID)

        let blogType: String
        switch blog.analyticsType {
        case .wpcom: blogType = "wpcom"
        case .jetpack: blogType = "jetpack"
        case .core: blogType = "self-hosted"
        }
        let properties: [AnyHashable: Any] = [
            "custom_post_type_count": classification.custom.count,
            "custom_post_type_slugs": Self.jsonArray(classification.custom),
            "hidden_post_type_count": classification.hidden.count,
            "hidden_post_type_slugs": Self.jsonArray(classification.hidden),
            "blog_type": blogType
        ]
        track(.customPostTypesFetched, properties, blog.analyticsProperties)
    }

    // Tracks drops the whole event when a property is an array, so the slugs are sent as a JSON string.
    private static func jsonArray(_ strings: [String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: strings) else {
            return "[]"
        }
        return String(decoding: data, as: UTF8.self)
    }
}
