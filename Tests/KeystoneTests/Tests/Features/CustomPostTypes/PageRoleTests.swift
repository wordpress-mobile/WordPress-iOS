import Testing
@testable import WordPress

@Suite("markPageRoles")
struct MarkPageRolesTests {

    private func makeItem(id: Int64) -> CustomPostCollectionItem {
        let post = CustomPostCollectionDisplayPost(
            date: Date(),
            title: "Page \(id)",
            content: nil,
            status: .publish
        )
        return CustomPostCollectionItem(id: id, post: post, state: .loading)
    }

    @Test("marks homepage and posts page on separate items")
    func marksHomepageAndPostsPage() {
        var items = [makeItem(id: 1), makeItem(id: 2), makeItem(id: 3)]
        items.markPageRoles(homepageID: 1, postsPageID: 2)
        #expect(items[0].pageRole == .homepage)
        #expect(items[1].pageRole == .postsPage)
        #expect(items[2].pageRole == nil)
    }

    @Test("nil IDs result in no roles assigned")
    func nilIDs() {
        var items = [makeItem(id: 1), makeItem(id: 2)]
        items.markPageRoles(homepageID: nil, postsPageID: nil)
        #expect(items[0].pageRole == nil)
        #expect(items[1].pageRole == nil)
    }

    @Test("only homepage ID provided")
    func onlyHomepageID() {
        var items = [makeItem(id: 1), makeItem(id: 2)]
        items.markPageRoles(homepageID: 1, postsPageID: nil)
        #expect(items[0].pageRole == .homepage)
        #expect(items[1].pageRole == nil)
    }

    @Test("only posts page ID provided")
    func onlyPostsPageID() {
        var items = [makeItem(id: 1), makeItem(id: 2)]
        items.markPageRoles(homepageID: nil, postsPageID: 2)
        #expect(items[0].pageRole == nil)
        #expect(items[1].pageRole == .postsPage)
    }

    @Test("ID not found in items does nothing")
    func idNotFound() {
        var items = [makeItem(id: 1)]
        items.markPageRoles(homepageID: 99, postsPageID: 100)
        #expect(items[0].pageRole == nil)
    }

    @Test("same ID for both roles assigns postsPage (last-write wins)")
    func sameIDForBothRoles() {
        var items = [makeItem(id: 1)]
        items.markPageRoles(homepageID: 1, postsPageID: 1)
        #expect(items[0].pageRole == .postsPage)
    }
}
