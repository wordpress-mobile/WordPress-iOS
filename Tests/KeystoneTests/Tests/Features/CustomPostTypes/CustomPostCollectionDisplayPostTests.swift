import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPress
@testable import WordPressData

@MainActor
struct CustomPostCollectionDisplayPostTests {
    @Test
    func missingTitleUsesPlaceholder() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        let post = CustomPostCollectionDisplayPost(makePost(title: nil), blog: blog)

        #expect(post.titleForDisplay == "(no title)")
    }

    @Test(arguments: [
        ("Tea &amp; Coffee", "Tea & Coffee"),
        ("AT&T", "AT&T"),
        // SwiftSoup accepts missing semicolons, unlike the Rust decoder.
        ("&unknown; &amp Rain; Q&A; Rock &amp Roll;", "&unknown; & Rain; Q&A; Rock & Roll;"),
        ("&quot;Hello&quot; &apos;world&apos;", "\"Hello\" 'world'"),
        ("Don&rsquo;t Stop&hellip; 2020&ndash;2026 Caf&eacute; &copy; &euro;5", "Don’t Stop… 2020–2026 Café © €5"),
        ("Em &#x2014; Dash &#X2014;", "Em — Dash —"),
        ("&amp;", "&"),
        ("100&#37; &#; &#x;", "100% &#; &#x;"),
        ("Party &#x1f389; &#127881;", "Party 🎉 🎉"),
        ("😀 &amp; 🌧️", "😀 & 🌧️"),
        ("مرحبا &amp; سلام", "مرحبا & سلام"),
        ("&lt;strong&gt;Hello&lt;/strong&gt;", "<strong>Hello</strong>"),
        ("<strong>Hello</strong>", "<strong>Hello</strong>"),
        ("&amp;lt;strong&amp;gt;", "&lt;strong&gt;"),
        ("   &amp;   ", "   &   "),
        ("&nbsp;&#160;", "\u{a0}\u{a0}"),
        ("&#10;&#9;", "\n\t"),
        ("", "")
    ])
    func decodesRenderedTitleOnce(rendered: String, decoded: String) {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        let entity = makePost(title: PostTitleWithEditContext(raw: "Different raw title", rendered: rendered))

        let post = CustomPostCollectionDisplayPost(entity, blog: blog)
        let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(post.title == decoded)
        #expect(post.titleForDisplay == (trimmed.isEmpty ? "(no title)" : trimmed))
        #expect(entity.title?.raw == "Different raw title")
        #expect(entity.title?.rendered == rendered)
    }

    @Test
    func renderedTitleDoesNotRequireRawTitle() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        let entity = makePost(title: PostTitleWithEditContext(raw: nil, rendered: "Only &amp; Rendered"))

        let post = CustomPostCollectionDisplayPost(entity, blog: blog)

        #expect(post.titleForDisplay == "Only & Rendered")
        #expect(entity.title?.raw == nil)
    }

    @Test
    func hidesStatusMatchingThePrimaryStatus() {
        let post = makeDisplayPost(status: .draft, primaryStatus: .draft)

        #expect(post.badges.isEmpty)
    }

    @Test(arguments: [
        (PostStatus.publish, "Published", "checkmark.circle", PostListBadge.Tint.success),
        (.draft, "Draft", "pencil", .neutral),
        (.future, "Scheduled", "calendar", .info),
        (.pending, "Pending", "clock", .warning),
        (.private, "Private", "lock", .neutral),
        (.trash, "Trashed", "trash", .error)
    ])
    func statusBadge(status: PostStatus, text: String, systemImage: String, tint: PostListBadge.Tint) {
        let post = makeDisplayPost(status: status, primaryStatus: .any)

        #expect(post.badges == [PostListBadge(text: text, systemImage: systemImage, tint: tint)])
    }

    @Test
    func customStatusIsShownVerbatimWithoutAnIcon() {
        let post = makeDisplayPost(status: .custom("archived"))

        #expect(post.badges == [PostListBadge(text: "archived", systemImage: nil, tint: .neutral)])
    }

    @Test
    func stickyBadgeFollowsTheStatus() {
        let post = makeDisplayPost(status: .private, sticky: true)

        #expect(post.badges.map(\.text) == ["Private", "Sticky"])
        #expect(post.badges[1] == PostListBadge(text: "Sticky", systemImage: "pin", tint: .neutral))
    }

    @Test
    func stickyBadgeAloneWhenStatusIsHidden() {
        let post = makeDisplayPost(status: .publish, sticky: true)

        #expect(post.badges.map(\.text) == ["Sticky"])
    }

    @Test(arguments: [
        (PageRole.homepage, "Homepage", "house.fill"),
        (.postsPage, "Posts page", "paragraphsign")
    ])
    func pageRoleBadgeComesLast(pageRole: PageRole, text: String, systemImage: String) {
        let post = makeDisplayPost(status: .draft, pageRole: pageRole)

        #expect(post.badges.map(\.text) == ["Draft", text])
        #expect(post.badges[1] == PostListBadge(text: text, systemImage: systemImage, tint: .neutral))
    }

    private func makeDisplayPost(
        status: PostStatus,
        sticky: Bool = false,
        primaryStatus: PostStatus = .publish,
        pageRole: PageRole? = nil
    ) -> CustomPostCollectionDisplayPost {
        CustomPostCollectionDisplayPost(
            date: Date(timeIntervalSince1970: 0),
            title: "Title",
            content: nil,
            status: status,
            sticky: sticky,
            primaryStatus: primaryStatus,
            pageRole: pageRole
        )
    }

    private func makePost(title: PostTitleWithEditContext?) -> AnyPostWithEditContext {
        AnyPostWithEditContext(
            id: PostId(1),
            date: WpDateString(value: "2025-01-01T00:00:00"),
            dateGmt: Date(timeIntervalSince1970: 0),
            guid: PostGuidWithEditContext(raw: nil, rendered: ""),
            link: "https://example.com",
            modified: WpDateString(value: "2025-01-01T00:00:00"),
            modifiedGmt: Date(timeIntervalSince1970: 0),
            slug: "test-post",
            status: .draft,
            postType: "post",
            password: nil,
            permalinkTemplate: nil,
            generatedSlug: nil,
            title: title,
            content: PostContentWithEditContext(raw: nil, rendered: "", protected: nil, blockVersion: nil),
            author: nil,
            excerpt: nil,
            featuredMedia: nil,
            commentStatus: .open,
            pingStatus: .open,
            format: nil,
            meta: nil,
            sticky: nil,
            template: "",
            categories: nil,
            tags: nil,
            parent: nil,
            menuOrder: nil,
            additionalFields: nil
        )
    }
}
