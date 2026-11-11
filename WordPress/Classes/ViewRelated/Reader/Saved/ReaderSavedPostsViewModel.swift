import Combine
import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressShared

/// A post in the Saved screen.
struct ReaderSavedPostRow: Identifiable, Equatable {
    /// Where tapping the row goes.
    enum Destination: Equatable {
        case post(postID: UInt64, siteID: UInt64)
        case feedItem(feedItemID: UInt64, feedID: UInt64)
        case url(URL)
    }

    let id: String
    let key: ReaderSavedKey
    /// The post's identity, which unsaves every key it may be saved under. `nil` for a post saved
    /// just now that the saved list hasn't sent yet.
    let identity: ReaderPostSaveIdentity?
    let title: String
    let excerpt: String?
    let siteName: String?
    /// The site's icon, or an RSS feed's image.
    let siteIconURL: URL?
    let authorName: String?
    let featuredImageURL: URL?
    /// The names of the post's first few tags.
    let tags: [String]
    /// `0` also for a post that can't have comments, such as an RSS post.
    let commentCount: UInt64
    let dateSaved: Date?
    let destination: Destination?

    init(_ item: ReaderSavedListItem) {
        let post = item.post
        let url = post?.identity.url ?? Self.url(of: item.key)

        id = ReaderSavedPostsSync.storageKey(for: item.key)
        key = item.key
        identity = post?.identity
        dateSaved = item.dateSaved
        siteName = (post?.siteName).flatMap(Self.plainText)
        siteIconURL = (post?.siteIconUrl).flatMap { URL(string: $0) }
        authorName = (post?.authorName).flatMap(Self.plainText)
        excerpt = (post?.excerpt).flatMap(Self.plainText)
        featuredImageURL = (post?.featuredImage).flatMap { URL(string: $0) }
        tags = Self.tagNames(post?.tags)
        commentCount = post?.commentCount ?? 0
        destination = Self.destination(for: item.key, post: post, url: url)

        // A page saved by URL may have nothing but its address.
        title =
            (post?.title).flatMap(Self.plainText)
            ?? url.flatMap { URL(string: $0)?.host() ?? $0 }
            ?? ""
    }

    private static func destination(
        for key: ReaderSavedKey,
        post: ReaderPostRecord?,
        url: String?
    ) -> Destination? {
        switch key {
        case let .post(blogId, postId) where postId > 0:
            return .post(postID: UInt64(postId), siteID: blogId)
        case .post:
            break
        case let .feedItem(feedItemId):
            if let feedID = post?.identity.feedId, feedID > 0 {
                return .feedItem(feedItemID: feedItemId, feedID: feedID)
            }
        case .url:
            break
        }
        return url.flatMap(URL.init(string:)).map(Destination.url)
    }

    private static func url(of key: ReaderSavedKey) -> String? {
        if case let .url(url) = key { url } else { nil }
    }

    static func tagNames(_ tags: [ReaderPostTag]?, limit: Int = 3) -> [String] {
        Array((tags ?? []).compactMap { plainText($0.displayName ?? $0.name) }.prefix(limit))
    }

    private static func plainText(_ html: String) -> String? {
        (html as NSString).makePlainText().nonEmptyString()
    }
}

/// The Saved screen's list, read from the account's saved posts in `WordPressApiCache`. The rows
/// reload whenever the cache changes in a way the list shows, so saves and unsaves made anywhere in
/// the app, refreshes and pages all show up here.
@MainActor
final class ReaderSavedPostsViewModel: ObservableObject {
    @Published private(set) var rows: [ReaderSavedPostRow] = []
    @Published private(set) var hasMore = false
    /// Whether the rows are what the cache has, so an empty list means there are no saved posts.
    @Published private(set) var hasLoaded = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    /// Why the last refresh failed. Only shown while there are no rows to show.
    @Published private(set) var errorMessage: String?

    private let collection: any ReaderSavedPostsCollectionProtocol
    private let service: any ReaderSavedServiceProtocol
    private let cacheUpdates: AnyPublisher<UpdateHook, Never>
    private let presentError: @MainActor (String) -> Void
    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    init(
        service: any ReaderSavedServiceProtocol,
        collection: (any ReaderSavedPostsCollectionProtocol)? = nil,
        cacheUpdates: AnyPublisher<UpdateHook, Never>,
        presentError: @escaping @MainActor (String) -> Void
    ) {
        self.service = service
        self.collection = collection ?? service.savedPosts()
        self.cacheUpdates = cacheUpdates
        self.presentError = presentError
    }

    deinit {
        updatesTask?.cancel()
    }

    /// Shows what the cache has straight away, then catches up with the server.
    func onAppear() async {
        guard !hasStarted else { return }
        hasStarted = true
        observeCacheUpdates()
        await reloadFromCache()
        await refresh()
    }

    /// Reloads the first page. Pages past it stay, so the list is still whole offline.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            _ = try await collection.refresh()
            errorMessage = nil
        } catch {
            Loggers.app.error("Reader saved posts: refreshing the list failed: \(String(describing: error))")
            errorMessage = Self.message(for: error)
        }
        await reloadFromCache()
    }

    /// Like ``refresh()``, and tells the user when it fails while there are posts on screen.
    func pullToRefresh() async {
        await refresh()
        if let errorMessage, !rows.isEmpty {
            presentError(errorMessage)
        }
    }

    /// Loads the next page once the given row, the last one, comes on screen.
    func loadMoreIfNeeded(after row: ReaderSavedPostRow) async {
        guard row.id == rows.last?.id else { return }
        await loadMore()
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isRefreshing else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            _ = try await collection.loadNextPage()
        } catch ReaderSavedError.StaleLoadMore {
            // A refresh started while the page loaded, and replaced it.
        } catch {
            Loggers.app.error("Reader saved posts: loading the next page failed: \(String(describing: error))")
        }
        await reloadFromCache()
    }

    /// Unsaves the post. It leaves the list straight away, and comes back if the request fails.
    func unsave(_ row: ReaderSavedPostRow) async {
        rows.removeAll { $0.id == row.id }
        do {
            if let identity = row.identity {
                try await service.unsave(post: identity)
            } else {
                try await service.unsaveKey(key: row.key)
            }
        } catch {
            Loggers.app.error("Reader saved posts: unsave failed: \(String(describing: error))")
            presentError(Strings.unsaveFailed)
            await reloadFromCache()
        }
    }

    func reloadFromCache() async {
        do {
            let items = try await collection.loadItems()
            let info = try collection.listInfo()
            rows = items.map(ReaderSavedPostRow.init)
            hasMore = info.hasMore ?? false
            hasLoaded = true
        } catch {
            Loggers.app.error("Reader saved posts: reading the list failed: \(String(describing: error))")
        }
    }

    private func observeCacheUpdates() {
        let collection = collection
        let batches =
            cacheUpdates
            .filter { collection.isRelevantUpdate(hook: $0) }
            .collect(.byTime(DispatchQueue.main, .milliseconds(50)))
            .values
        updatesTask = Task { [weak self] in
            for await _ in batches {
                await self?.reloadFromCache()
            }
        }
    }

    private static func message(for error: Error) -> String {
        if case let ReaderSavedError.Api(apiError) = error {
            return apiError.localizedDescription
        }
        return error.localizedDescription
    }
}

private enum Strings {
    static let unsaveFailed = NSLocalizedString(
        "reader.savedPosts.unsave.error",
        value: "Could not remove the post from your saved posts.",
        comment: "Shown in Reader's Saved screen when removing a saved post fails."
    )
}
