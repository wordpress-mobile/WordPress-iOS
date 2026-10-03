import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
import WordPressData
import WordPressShared

@testable import WordPress

private let titleOnly: [PostTypeSupports: JsonValue] = [.title: .bool(true)]

struct PostTypeClassificationTests {
    @Test(arguments: [
        (true, true, false),
        (false, true, true),
        (true, false, true)
    ])
    func unlistedPluginTypeIsHidden(viewable: Bool, showUi: Bool, supportsEditor: Bool) {
        let postType = makeTestPostType(
            slug: "plugin_type",
            viewable: viewable,
            showUi: showUi,
            supports: supportsEditor ? [.title: .bool(true), .editor: .bool(true)] : titleOnly
        )
        let classification = PostTypeClassification([postType])
        #expect(classification.custom.isEmpty)
        #expect(classification.hidden == ["plugin_type"])
    }

    @Test func coreTypesAreNeitherCustomNorHidden() {
        let classification = PostTypeClassification([
            makeTestPostType(slug: "post", restBase: "posts"),
            makeTestPostType(slug: "page", restBase: "pages"),
            makeTestPostType(slug: "attachment", restBase: "media", supports: titleOnly),
            // Excluded by name even when it passes every other check.
            makeTestPostType(slug: "attachment", restBase: "media"),
            makeTestPostType(slug: "wp_block", restBase: "blocks", viewable: false),
            makeTestPostType(slug: "nav_menu_item", restBase: "menu-items", viewable: false, showUi: false)
        ])
        #expect(classification.custom.isEmpty)
        #expect(classification.hidden.isEmpty)
    }

    @Test func listedCorePrefixedTypeIsCustom() {
        let classification = PostTypeClassification([makeTestPostType(slug: "wp_listed")])
        #expect(classification.custom == ["wp_listed"])
        #expect(classification.hidden.isEmpty)
    }

    @Test func unlistedCorePrefixedTypeIsNotHidden() {
        let classification = PostTypeClassification([makeTestPostType(slug: "wp_template", viewable: false)])
        #expect(classification.custom.isEmpty)
        #expect(classification.hidden.isEmpty)
    }

    @Test func slugsAreSortedAscending() {
        let classification = PostTypeClassification([
            makeTestPostType(slug: "product"),
            makeTestPostType(slug: "shop_order", showUi: false),
            makeTestPostType(slug: "job_listing"),
            makeTestPostType(slug: "give_forms", supports: titleOnly)
        ])
        #expect(classification.custom == ["job_listing", "product"])
        #expect(classification.hidden == ["give_forms", "shop_order"])
    }
}

@MainActor
struct CustomPostTypeUsageTrackerTests {
    private struct Event {
        let event: WPAnalyticsEvent
        let properties: [AnyHashable: Any]
        let blogProperties: BlogAnalyticsProperties
    }

    private let contextManager = ContextManager.forTesting()
    private var context: NSManagedObjectContext { contextManager.mainContext }

    @Test func sendsCountsSlugsAndSite() throws {
        let blog = BlogBuilder(context, dotComID: 42).isNotHostedAtWPcom().build()
        let classification = PostTypeClassification([
            makeTestPostType(slug: "product"),
            makeTestPostType(slug: "job_listing"),
            makeTestPostType(slug: "give_forms", supports: titleOnly)
        ])

        let event = try reportedEvent(for: blog, classification)

        #expect(event.event == .customPostTypesFetched)
        #expect(event.event.value == "custom_post_types_fetched")
        #expect(event.properties["custom_post_type_count"] as? Int == 2)
        #expect(event.properties["custom_post_type_slugs"] as? String == #"["job_listing","product"]"#)
        #expect(event.properties["hidden_post_type_count"] as? Int == 1)
        #expect(event.properties["hidden_post_type_slugs"] as? String == #"["give_forms"]"#)
        #expect(event.blogProperties.dotComID == 42)
    }

    @Test(arguments: [
        (42, true, "wpcom"),
        (42, false, "jetpack"),
        (nil, false, "self-hosted")
    ])
    func blogType(dotComID: Int?, isHostedAtWPcom: Bool, expected: String) throws {
        let blog = BlogBuilder(context, dotComID: dotComID.map { NSNumber(value: $0) })
            .with(isHostedAtWPCom: isHostedAtWPcom)
            .build()

        let event = try reportedEvent(for: blog)

        #expect(event.properties["blog_type"] as? String == expected)
        #expect(event.blogProperties.dotComID == dotComID)
    }

    @Test func sendsOncePerSite() {
        var events: [Event] = []
        let tracker = makeTracker { events.append($0) }
        let blog = TaggedManagedObjectID(BlogBuilder(context).build())
        let other = TaggedManagedObjectID(BlogBuilder(context).build())

        #expect(!tracker.hasReported(blog))
        tracker.report(PostTypeClassification([makeTestPostType(slug: "product")]), for: blog)
        tracker.report(PostTypeClassification([makeTestPostType(slug: "job_listing")]), for: blog)
        #expect(events.count == 1)
        #expect(tracker.hasReported(blog))

        #expect(!tracker.hasReported(other))
        tracker.report(PostTypeClassification([]), for: other)
        #expect(events.count == 2)
    }

    @Test func sendsEmptySets() throws {
        let event = try reportedEvent(for: BlogBuilder(context).build())

        #expect(event.properties["custom_post_type_count"] as? Int == 0)
        #expect(event.properties["custom_post_type_slugs"] as? String == "[]")
        #expect(event.properties["hidden_post_type_count"] as? Int == 0)
        #expect(event.properties["hidden_post_type_slugs"] as? String == "[]")
    }

    private func makeTracker(recordingInto events: @escaping (Event) -> Void) -> CustomPostTypeUsageTracker {
        CustomPostTypeUsageTracker(coreDataStack: contextManager) {
            events(Event(event: $0, properties: $1, blogProperties: $2))
        }
    }

    private func reportedEvent(
        for blog: Blog,
        _ classification: PostTypeClassification = PostTypeClassification([])
    ) throws -> Event {
        var events: [Event] = []
        makeTracker { events.append($0) }.report(classification, for: TaggedManagedObjectID(blog))
        #expect(events.count == 1)
        return try #require(events.first)
    }
}
