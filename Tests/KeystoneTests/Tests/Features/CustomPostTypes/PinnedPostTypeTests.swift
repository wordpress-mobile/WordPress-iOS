import Testing

@testable import WordPress

@Suite("PinnedPostType")
struct PinnedPostTypeTests {
    @Test("identifies the built-in post type")
    func identifiesPosts() {
        #expect(PinnedPostType.posts.isBuiltInPostOrPage)
    }

    @Test("identifies the built-in page type")
    func identifiesPages() {
        #expect(PinnedPostType.pages.isBuiltInPostOrPage)
    }

    @Test("does not identify a custom post type as built-in")
    func acceptsCustomPostType() {
        let postType = PinnedPostType(slug: "book", name: "Books", icon: nil)

        #expect(!postType.isBuiltInPostOrPage)
    }
}
