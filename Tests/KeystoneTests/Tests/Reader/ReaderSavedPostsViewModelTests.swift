import Combine
import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress

@MainActor
struct ReaderSavedPostsViewModelTests {
    private let service = FakeReaderSavedService()
    private let collection = FakeReaderSavedPostsCollection()
    private let cacheUpdates = PassthroughSubject<UpdateHook, Never>()
    private let errors = ErrorRecorder()

    private func makeViewModel() -> ReaderSavedPostsViewModel {
        let errors = errors
        return ReaderSavedPostsViewModel(
            service: service,
            collection: collection,
            cacheUpdates: cacheUpdates.eraseToAnyPublisher(),
            presentError: { errors.messages.append($0) }
        )
    }

    // MARK: - Rows

    @Test("A WordPress.com post shows its details and opens as a post")
    func rowForPost() {
        let row = ReaderSavedPostRow(Self.postItem(postID: 1, siteID: 100, title: "Hello &amp; welcome"))

        #expect(row.id == "post:100:1")
        #expect(row.title == "Hello & welcome")
        #expect(row.excerpt == "An excerpt")
        #expect(row.siteName == "Site")
        #expect(row.authorName == "Author")
        #expect(row.featuredImageURL == URL(string: "https://example.com/image.jpg"))
        #expect(row.dateSaved == Date(timeIntervalSince1970: 100))
        #expect(row.destination == .post(postID: 1, siteID: 100))
    }

    @Test("A feed item opens as a feed post when its feed is known")
    func rowForFeedItem() {
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

        #expect(ReaderSavedPostRow(item).destination == .feedItem(feedItemID: 55, feedID: 7))
    }

    @Test("A page saved by URL shows its host and opens in a web view")
    func rowForURL() {
        let item = ReaderSavedListItem(
            key: .url(url: "https://example.com/some/page"),
            isRecent: true,
            isLocalOnly: false
        )

        let row = ReaderSavedPostRow(item)

        #expect(row.title == "example.com")
        #expect(row.identity == nil)
        #expect(row.destination == .url(URL(string: "https://example.com/some/page")!))
    }

    // MARK: - Loading

    @Test("Appearing shows the cache, then refreshes")
    func appearLoadsThenRefreshes() async {
        collection.items = [Self.postItem(postID: 1, siteID: 100)]
        collection.info = ReaderSavedListInfo(state: .idle, hasMore: true)

        let viewModel = makeViewModel()
        await viewModel.onAppear()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.rows.map(\.id) == ["post:100:1"])
        #expect(viewModel.hasMore)
        #expect(collection.refreshCount == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("A failed refresh with nothing cached shows an error")
    func failedRefreshShowsError() async {
        collection.refreshError = URLError(.notConnectedToInternet)

        let viewModel = makeViewModel()
        await viewModel.onAppear()

        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(errors.messages.isEmpty)
    }

    @Test("A failed pull to refresh over cached posts keeps them and shows a notice")
    func failedPullToRefreshKeepsRows() async {
        collection.items = [Self.postItem(postID: 1, siteID: 100)]
        collection.refreshError = URLError(.notConnectedToInternet)

        let viewModel = makeViewModel()
        await viewModel.pullToRefresh()

        #expect(viewModel.rows.count == 1)
        #expect(errors.messages.count == 1)
    }

    @Test("The next page loads only from the last row, and only when there's more")
    func loadMoreFromLastRow() async {
        collection.items = [Self.postItem(postID: 1, siteID: 100), Self.postItem(postID: 2, siteID: 100)]
        collection.info = ReaderSavedListInfo(state: .idle, hasMore: true)

        let viewModel = makeViewModel()
        await viewModel.reloadFromCache()
        await viewModel.loadMoreIfNeeded(after: viewModel.rows[0])
        #expect(collection.nextPageCount == 0)

        await viewModel.loadMoreIfNeeded(after: viewModel.rows[1])
        #expect(collection.nextPageCount == 1)

        collection.info = ReaderSavedListInfo(state: .idle, hasMore: false)
        await viewModel.reloadFromCache()
        await viewModel.loadMoreIfNeeded(after: viewModel.rows[1])
        #expect(collection.nextPageCount == 1)
    }

    @Test("A change to the cache reloads the rows")
    func cacheUpdateReloads() async throws {
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        #expect(viewModel.rows.isEmpty)

        collection.items = [Self.postItem(postID: 1, siteID: 100)]
        cacheUpdates.send(UpdateHook(action: .insert, dbName: "main", table: .readerStreamItems, rowId: 1))

        for _ in 0..<50 where viewModel.rows.isEmpty {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(viewModel.rows.map(\.id) == ["post:100:1"])
    }

    // MARK: - Unsaving

    @Test("Unsaving removes the row straight away and unsaves every key of the post")
    func unsaveRemovesRow() async {
        collection.items = [Self.postItem(postID: 1, siteID: 100), Self.postItem(postID: 2, siteID: 100)]
        let viewModel = makeViewModel()
        await viewModel.reloadFromCache()

        await viewModel.unsave(viewModel.rows[0])

        #expect(viewModel.rows.map(\.id) == ["post:100:2"])
        #expect(service.unsavedIdentities.map(\.id) == [1])
        #expect(errors.messages.isEmpty)
    }

    @Test("A save the list hasn't sent yet is unsaved by its key")
    func unsaveByKey() async {
        collection.items = [
            ReaderSavedListItem(key: .url(url: "https://example.com/a"), isRecent: true, isLocalOnly: false)
        ]
        let viewModel = makeViewModel()
        await viewModel.reloadFromCache()

        await viewModel.unsave(viewModel.rows[0])

        #expect(service.unsavedKeys == [.url(url: "https://example.com/a")])
    }

    @Test("A failed unsave puts the row back and shows a notice")
    func failedUnsaveRestoresRow() async {
        collection.items = [Self.postItem(postID: 1, siteID: 100)]
        service.unsaveError = URLError(.timedOut)
        let viewModel = makeViewModel()
        await viewModel.reloadFromCache()

        await viewModel.unsave(viewModel.rows[0])

        #expect(viewModel.rows.count == 1)
        #expect(errors.messages.count == 1)
    }

    // MARK: - Helpers

    static func postItem(postID: UInt64, siteID: UInt64, title: String = "Title") -> ReaderSavedListItem {
        let identity = ReaderPostSaveIdentity(
            id: postID,
            siteId: siteID,
            feedId: nil,
            feedItemId: nil,
            isExternal: false,
            url: "https://example.com/\(postID)"
        )
        return ReaderSavedListItem(
            key: .post(blogId: siteID, postId: Int64(postID)),
            dateSaved: Date(timeIntervalSince1970: 100),
            post: ReaderPostRecord(
                key: .post(blogId: siteID, postId: Int64(postID)),
                identity: identity,
                title: title,
                excerpt: "<p>An excerpt</p>",
                authorName: "Author",
                featuredImage: "https://example.com/image.jpg",
                siteName: "Site"
            ),
            isRecent: false,
            isLocalOnly: false
        )
    }
}

@MainActor
private final class ErrorRecorder {
    var messages: [String] = []
}

/// A saved list that answers from what it's given. Tests run on the main actor, so the
/// unsynchronized state is only touched from there.
final class FakeReaderSavedPostsCollection: ReaderSavedPostsCollectionProtocol, @unchecked Sendable {
    var items: [ReaderSavedListItem] = []
    var info = ReaderSavedListInfo(state: .idle)
    var refreshError: Error?
    /// Pages the server has past what's in `items`, which `loadNextPage()` adds one at a time.
    var nextPages: [[ReaderSavedListItem]] = []

    private(set) var refreshCount = 0
    private(set) var nextPageCount = 0

    func isRelevantUpdate(hook: UpdateHook) -> Bool { true }

    func listInfo() throws -> ReaderSavedListInfo { info }

    func loadItems() async throws -> [ReaderSavedListItem] { items }

    func loadNextPage() async throws -> ReaderSavedPageResult {
        nextPageCount += 1
        guard !nextPages.isEmpty else {
            return ReaderSavedPageResult(postCount: 0, hasMore: false)
        }
        let page = nextPages.removeFirst()
        items += page
        return ReaderSavedPageResult(postCount: UInt64(page.count), hasMore: !nextPages.isEmpty)
    }

    func refresh() async throws -> ReaderSavedPageResult {
        refreshCount += 1
        if let refreshError { throw refreshError }
        return ReaderSavedPageResult(postCount: UInt64(items.count), hasMore: info.hasMore ?? false)
    }
}
