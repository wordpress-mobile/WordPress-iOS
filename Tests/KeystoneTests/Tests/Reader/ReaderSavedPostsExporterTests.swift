import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress

@MainActor
struct ReaderSavedPostsExporterTests {

    // MARK: - Export

    @Test("Nothing is exported when the account has no saved posts")
    func exportReturnsNilWhenEmpty() async throws {
        let collection = FakeReaderSavedPostsCollection()

        #expect(try await ReaderSavedPostsExporter().export(collection: collection) == nil)
    }

    @Test("Export writes the account's saved list, and the file reads back")
    func exportThenParse() async throws {
        let collection = FakeReaderSavedPostsCollection()
        collection.items = [
            ReaderSavedPostsViewModelTests.postItem(postID: 1, siteID: 100, title: "First &amp; best"),
            ReaderSavedPostsViewModelTests.postItem(postID: 2, siteID: 100)
        ]

        let fileURL = try #require(try await ReaderSavedPostsExporter().export(collection: collection))
        let posts = try ReaderSavedPostsExporter.parseExportFile(at: fileURL)

        #expect(posts.map(\.postID) == [1, 2])
        #expect(posts[0].title == "First & best")
        #expect(posts[0].summary == "An excerpt")
        #expect(posts[0].siteName == "Site")
        #expect(posts[0].author == "Author")
        #expect(posts[0].url == "https://example.com/1")
        #expect(posts[0].featuredImageURL == "https://example.com/image.jpg")
        #expect(posts[0].siteID == 100)
        #expect(!posts[0].isFeed)
    }

    @Test("Export includes the pages nobody has scrolled to yet")
    func exportLoadsEveryPage() async throws {
        let collection = FakeReaderSavedPostsCollection()
        collection.items = [ReaderSavedPostsViewModelTests.postItem(postID: 1, siteID: 100)]
        collection.info = ReaderSavedListInfo(state: .idle, hasMore: true)
        collection.nextPages = [
            [ReaderSavedPostsViewModelTests.postItem(postID: 2, siteID: 100)],
            [ReaderSavedPostsViewModelTests.postItem(postID: 3, siteID: 100)]
        ]

        let fileURL = try #require(try await ReaderSavedPostsExporter().export(collection: collection))
        let posts = try ReaderSavedPostsExporter.parseExportFile(at: fileURL)

        #expect(posts.map(\.postID) == [1, 2, 3])
    }

    @Test("A feed item is exported with its feed identifiers")
    func exportFeedItem() {
        let identity = ReaderPostSaveIdentity(
            id: 55,
            siteId: nil,
            feedId: 7,
            feedItemId: 55,
            isExternal: true,
            url: "https://feed.example.com/item"
        )
        let item = ReaderSavedListItem(
            key: .feedItem(feedItemId: 55),
            post: ReaderPostRecord(key: .feedItem(feedItemId: 55), identity: identity, title: "Feed post"),
            isRecent: false,
            isLocalOnly: false
        )

        let post = ReaderSavedPostsExporter.exportedPost(for: item)

        #expect(post.isFeed)
        #expect(post.feedID == 7)
        #expect(post.feedItemID == 55)
        #expect(post.siteID == nil)
    }

    @Test("A post is exported with all its tags")
    func exportTags() {
        let identity = ReaderPostSaveIdentity(
            id: 1,
            siteId: 100,
            feedId: nil,
            feedItemId: nil,
            isExternal: false,
            url: "https://example.com/1"
        )
        let tags = ["One", "Two", "Three", "Four"].map { ReaderPostTag(slug: $0.lowercased(), name: $0) }
        let item = ReaderSavedListItem(
            key: .post(blogId: 100, postId: 1),
            post: ReaderPostRecord(key: .post(blogId: 100, postId: 1), identity: identity, tags: tags),
            isRecent: false,
            isLocalOnly: false
        )

        #expect(ReaderSavedPostsExporter.exportedPost(for: item).tags == ["One", "Two", "Three", "Four"])
    }

    @Test("A save the list hasn't sent yet is exported from its key")
    func exportRecentSave() {
        let item = ReaderSavedListItem(key: .post(blogId: 100, postId: 5), isRecent: true, isLocalOnly: false)

        let post = ReaderSavedPostsExporter.exportedPost(for: item)

        #expect(post.siteID == 100)
        #expect(post.postID == 5)
        #expect(!post.isFeed)
    }

    // MARK: - Parse

    @Test("A file that isn't a saved posts export is rejected")
    func parseRejectsOtherJSON() throws {
        let fileURL = try Self.write(Data(#"{"notPosts": true}"#.utf8))

        #expect(throws: ReaderSavedPostsExporter.ImportError.self) {
            try ReaderSavedPostsExporter.parseExportFile(at: fileURL)
        }
    }

    @Test("A file that isn't JSON is rejected")
    func parseRejectsNonJSON() throws {
        let fileURL = try Self.write(Data("not json".utf8))

        #expect(throws: (any Error).self) {
            try ReaderSavedPostsExporter.parseExportFile(at: fileURL)
        }
    }

    // MARK: - Import

    @Test("An exported WordPress.com post is saved under its site and post ID")
    func identityForSitePost() {
        let identity = ReaderSavedPostsExporter.identity(for: Self.exportedPost(siteID: 100, postID: 1))

        #expect(identity.savedKey == .post(blogId: 100, postId: 1))
    }

    @Test("An exported feed post is saved under its feed item")
    func identityForFeedPost() {
        let post = Self.exportedPost(siteID: nil, postID: 55, feedID: 7, feedItemID: 55, isFeed: true)

        #expect(ReaderSavedPostsExporter.identity(for: post).savedKey == .feedItem(feedItemId: 55))
    }

    @Test("Import sends the file's posts straight to the account")
    func importSavesToTheAccount() async throws {
        let service = FakeReaderSavedService()
        let store = ReaderSavedPostsStore(
            coreDataStack: ContextManager.forTesting(),
            track: { _, _ in },
            makeSession: { _ in
                .init(userID: 42, service: service, savedPosts: FakeReaderSavedPostsCollection(), client: nil)
            },
            removeAccountData: { _ in },
            observesAccountChanges: false
        )

        let result = await ReaderSavedPostsExporter.importPostsToAccount(
            [
                Self.exportedPost(siteID: 100, postID: 1),
                Self.exportedPost(siteID: nil, postID: 55, feedID: 7, feedItemID: 55, isFeed: true),
                Self.exportedPost(siteID: nil, postID: nil, url: "")
            ],
            store: store
        )

        #expect(result.imported == 2)
        #expect(result.skipped == 1)
        #expect(result.failed == 0)
        #expect(service.bulkImports == [[.post(blogId: 100, postId: 1), .feedItem(feedItemId: 55)]])
    }

    @Test("Import fails every post without an account")
    func importWithoutAccount() async {
        let store = ReaderSavedPostsStore(
            coreDataStack: ContextManager.forTesting(),
            track: { _, _ in },
            makeSession: { _ in nil },
            removeAccountData: { _ in },
            observesAccountChanges: false
        )

        let result = await ReaderSavedPostsExporter.importPostsToAccount(
            [Self.exportedPost(siteID: 100, postID: 1)],
            store: store
        )

        #expect(result.imported == 0)
        #expect(result.failed == 1)
    }

    // MARK: - Helpers

    static func exportedPost(
        siteID: UInt?,
        postID: UInt?,
        feedID: UInt? = nil,
        feedItemID: UInt? = nil,
        isFeed: Bool = false,
        url: String = "https://example.com/post"
    ) -> ReaderSavedPostsExporter.ExportedPost {
        ReaderSavedPostsExporter.ExportedPost(
            title: "",
            url: url,
            author: "",
            siteName: "",
            siteURL: "",
            date: nil,
            summary: "",
            tags: nil,
            featuredImageURL: nil,
            siteID: siteID,
            postID: postID,
            feedID: feedID,
            feedItemID: feedItemID,
            isFeed: isFeed
        )
    }

    static func write(_ data: Data) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try data.write(to: fileURL)
        return fileURL
    }
}
