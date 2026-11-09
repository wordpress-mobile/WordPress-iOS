import Testing
import Foundation
import CoreData
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache

@testable import WordPress
@testable import WordPressData

@MainActor
struct ReaderSavedPostsSyncTests {

    // MARK: - Identity

    @Test("A WordPress.com post is identified by its site and post ID")
    func identityForWordPressComPost() {
        let identity = ReaderSavedPostsSync.identity(
            postID: 67890,
            siteID: 12345,
            feedID: nil,
            feedItemID: nil,
            isExternal: false,
            permaLink: "https://example.com/post"
        )

        #expect(identity.id == 67890)
        #expect(identity.siteId == 12345)
        #expect(identity.feedId == nil)
        #expect(identity.feedItemId == nil)
        #expect(identity.isExternal == false)
        #expect(identity.url == "https://example.com/post")
        #expect(identity.savedKey == .post(blogId: 12345, postId: 67890))
    }

    @Test("A Jetpack post can also be saved under its feed item")
    func identityForJetpackPostWithFeedItem() {
        let identity = ReaderSavedPostsSync.identity(
            postID: 10,
            siteID: 20,
            feedID: 30,
            feedItemID: 40,
            isExternal: false,
            permaLink: nil
        )

        #expect(identity.savedKey == .post(blogId: 20, postId: 10))
        #expect(identity.savedKeys == [.post(blogId: 20, postId: 10), .feedItem(feedItemId: 40)])
    }

    @Test("An RSS post is saved under its feed item")
    func identityForExternalFeedPost() {
        let identity = ReaderSavedPostsSync.identity(
            postID: 555,
            siteID: 0,
            feedID: 30,
            feedItemID: 555,
            isExternal: true,
            permaLink: "https://feed.example.com/item"
        )

        #expect(identity.isExternal)
        #expect(identity.savedKey == .feedItem(feedItemId: 555))
    }

    @Test("The -1 default post ID and missing IDs aren't sent as IDs")
    func identityForMissingIDs() {
        let identity = ReaderSavedPostsSync.identity(
            postID: -1,
            siteID: nil,
            feedID: -1,
            feedItemID: nil,
            isExternal: false,
            permaLink: ""
        )

        #expect(identity.id == 0)
        #expect(identity.siteId == nil)
        #expect(identity.feedId == nil)
        #expect(identity.url == nil)
        #expect(identity.savedKey == nil)
    }

    @Test("A zero site and post ID can't be saved")
    func identityForZeroIDs() {
        let identity = ReaderSavedPostsSync.identity(
            postID: 0,
            siteID: 0,
            feedID: nil,
            feedItemID: nil,
            isExternal: false,
            permaLink: nil
        )

        #expect(identity.savedKey == nil)
    }

    @Test("A post with a zero site and feed is a page saved by URL")
    func identityForSnapshot() {
        let identity = ReaderSavedPostsSync.identity(
            postID: 99,
            siteID: 0,
            feedID: 0,
            feedItemID: nil,
            isExternal: true,
            permaLink: "https://example.com/page"
        )

        #expect(identity.savedKey == .url(url: "https://example.com/page"))
    }

    @Test("A local save carries the post's identity and what the list shows of it")
    func localSaveForReaderPost() {
        let context = ContextManager.forTesting().mainContext
        let post = context.insertNewObject(ofType: ReaderPost.self)
        post.postID = 7
        post.siteID = 8
        post.feedID = 9
        post.feedItemID = 10
        post.isExternal = false
        post.permaLink = "https://example.com/7"
        post.postTitle = "Title"
        post.summary = "Summary"
        post.featuredImage = ""
        post.blogName = "Site"
        post.blogURL = "https://example.com"

        let save = ReaderSavedPostsSync.localSave(for: post)

        #expect(
            save.identity
                == ReaderPostSaveIdentity(
                    id: 7,
                    siteId: 8,
                    feedId: 9,
                    feedItemId: 10,
                    isExternal: false,
                    url: "https://example.com/7"
                )
        )
        #expect(save.title == "Title")
        #expect(save.excerpt == "Summary")
        #expect(save.featuredImage == nil)
        #expect(save.siteName == "Site")
        #expect(save.siteUrl == "https://example.com")
        #expect(save.dateSaved == nil)
    }

    // MARK: - Import plan

    @Test("Saving a list keeps the posts' order and sends URLs separately")
    func importPlanSplitsURLKeys() {
        let identities = [
            Self.identity(id: 1, siteID: 100),
            Self.snapshot(url: "https://example.com/page"),
            Self.feedItem(55),
            Self.identity(id: 0, siteID: nil),
            Self.identity(id: 2, siteID: 100)
        ]

        let plan = ReaderSavedPostsSync.importPlan(for: identities)

        #expect(
            plan.bulkKeys == [
                .post(blogId: 100, postId: 1),
                .feedItem(feedItemId: 55),
                .post(blogId: 100, postId: 2)
            ]
        )
        #expect(plan.urls == ["https://example.com/page"])
        #expect(plan.unsaveableCount == 1)
    }

    @Test("A post listed twice is sent once")
    func importPlanSkipsDuplicates() {
        let plan = ReaderSavedPostsSync.importPlan(for: [
            Self.identity(id: 1, siteID: 100),
            Self.identity(id: 1, siteID: 100)
        ])

        #expect(plan.bulkKeys == [.post(blogId: 100, postId: 1)])
    }

    @Test("Keys the server didn't save are reported with their error")
    func rejectedKeys() {
        let keys: [ReaderSavedBulkKey] = [.post(blogId: 1, postId: 2), .feedItem(feedItemId: 3)]
        let results = [
            ReaderSavedBulkResult(key: keys[0], saved: true, error: nil),
            ReaderSavedBulkResult(key: nil, saved: false, error: "saved_limit_reached")
        ]

        let rejected = ReaderSavedPostsSync.rejectedKeys(keys, results: results)

        #expect(rejected.map(\.key) == [.feedItem(feedItemId: 3)])
        #expect(rejected.map(\.error) == ["saved_limit_reached"])
    }

    // MARK: - Helpers

    static func identity(id: UInt64, siteID: UInt64?) -> ReaderPostSaveIdentity {
        ReaderPostSaveIdentity(id: id, siteId: siteID, feedId: nil, feedItemId: nil, isExternal: false, url: nil)
    }

    static func feedItem(_ id: UInt64) -> ReaderPostSaveIdentity {
        ReaderPostSaveIdentity(id: id, siteId: 0, feedId: 7, feedItemId: id, isExternal: true, url: nil)
    }

    static func snapshot(url: String) -> ReaderPostSaveIdentity {
        ReaderPostSaveIdentity(id: 1, siteId: 0, feedId: 0, feedItemId: nil, isExternal: true, url: url)
    }
}

// MARK: - Store

@MainActor
final class ReaderSavedPostsStoreTests {
    private let contextManager = ContextManager.forTesting()
    private let service = FakeReaderSavedService()
    private let savedPosts = FakeReaderSavedPostsCollection()
    /// What the store did. A reference, so a store's work that finishes after the test doesn't
    /// reach back into the test.
    private let record = StoreRecord()
    private var sessionsMade: Int { record.sessionsMade }
    private var removedAccounts: [Int64] { record.removedAccounts }
    private var tracked: [(event: WPAnalyticsEvent, properties: [AnyHashable: Any])] { record.tracked }

    private func makeStore(observesAccountChanges: Bool = false) -> ReaderSavedPostsStore {
        ReaderSavedPostsStore(
            coreDataStack: contextManager,
            track: { [record] in record.tracked.append(($0, $1)) },
            makeSession: { [record, service, savedPosts] _ in
                record.sessionsMade += 1
                return .init(userID: 42, service: service, savedPosts: savedPosts, client: nil)
            },
            removeAccountData: { [record] in record.removedAccounts.append($0) },
            observesAccountChanges: observesAccountChanges
        )
    }

    @Test("Start hands the local saves to the account in the old Saved screen's order")
    func startImportsInSavedScreenOrder() async throws {
        // The old Saved screen sorted by `sortRank`, newest first, which isn't always `sortDate`.
        try makeSavedPost(postID: 1, siteID: 100, sortRank: 30, sortDate: Date(timeIntervalSince1970: 1))
        try makeSavedPost(postID: 2, siteID: 100, sortRank: 10, sortDate: Date(timeIntervalSince1970: 3))
        try makeSavedPost(postID: 3, siteID: 100, sortRank: 20, sortDate: Date(timeIntervalSince1970: 2))
        try makePost(postID: 4, siteID: 100)

        let store = makeStore()
        await store.start()?.value

        #expect(service.importedSaves.count == 1)
        #expect(service.importedSaves.first?.map(\.identity.id) == [1, 3, 2])
        #expect(service.importedSaves.first?.first?.title == "Post 1")
    }

    @Test("An import that sent posts refreshes the saved list, so the Saved screen shows them")
    func importRefreshesTheList() async throws {
        try makeSavedPost(postID: 1, siteID: 100)

        let store = makeStore()
        await store.start()?.value

        #expect(savedPosts.refreshCount == 1)
        #expect(service.refreshCount == 0)
    }

    @Test("When there was nothing to import, only the saved keys are refreshed")
    func emptyImportRefreshesKeys() async throws {
        let store = makeStore()
        await store.start()?.value

        #expect(service.importedSaves == [[]])
        #expect(savedPosts.refreshCount == 0)
        #expect(service.refreshCount == 1)
    }

    @Test("An import that ran before sends no event and doesn't refresh the list")
    func alreadyImported() async throws {
        try makeSavedPost(postID: 1, siteID: 100)
        service.alreadyImported = true

        let store = makeStore()
        await store.start()?.value

        #expect(tracked.isEmpty)
        #expect(savedPosts.refreshCount == 0)
        #expect(service.refreshCount == 1)
    }

    @Test("The import's event has its counts, and nothing that identifies a post")
    func importEvent() async throws {
        try makeSavedPost(postID: 1, siteID: 100)
        try makeSavedPost(postID: 2, siteID: 100)
        service.importReport = ReaderSavedImportReport(
            alreadyImported: false,
            imported: 1,
            rejected: [.post(blogId: 100, postId: 2)],
            unsaveable: 0
        )

        let store = makeStore()
        await store.start()?.value

        #expect(tracked.count == 1)
        #expect(tracked.first?.event == .readerSavedPostsAccountImport)
        let properties = try #require(tracked.first?.properties)
        #expect(properties["result"] as? String == "imported")
        #expect(properties["local_saves"] as? Int == 2)
        #expect(properties["imported"] as? Int == 1)
        #expect(properties["refused"] as? Int == 1)
        #expect(properties["unsaveable"] as? Int == 0)
        #expect(properties.count == 5)
    }

    @Test("A failed import sends its error kind, still refreshes, and runs again next time")
    func failedImportStillRefreshes() async throws {
        try makeSavedPost(postID: 1, siteID: 100)
        service.importError = URLError(.notConnectedToInternet)

        let store = makeStore()
        await store.start()?.value

        #expect(tracked.map(\.event) == [.readerSavedPostsAccountImport])
        #expect(tracked.first?.properties["result"] as? String == "failed")
        #expect(tracked.first?.properties["error_kind"] as? String == "network")
        #expect(service.refreshCount == 1)

        service.importError = nil
        await store.start()?.value

        #expect(service.importedSaves.count == 2)
        #expect(tracked.last?.properties["result"] as? String == "imported")
        #expect(savedPosts.refreshCount == 1)
    }

    @Test(
        "Import errors are reported by kind",
        arguments: [
            (ReaderSavedError.PostCannotBeSaved as Error, "post_cannot_be_saved"),
            (ReaderSavedError.UnexpectedImportResults(sent: 2, received: 1), "unexpected_import_results"),
            (URLError(.timedOut), "network"),
            (CocoaError(.coreData), "core_data"),
            (NSError(domain: "other", code: 1), "other")
        ]
    )
    func errorKinds(error: Error, kind: String) {
        #expect(ReaderSavedPostsSync.errorKind(for: error) == kind)
        #expect(ReaderSavedPostsSync.importProperties(for: error, saveCount: 3)["local_saves"] as? Int == 3)
    }

    @Test("The import runs once the account turns up, even if it wasn't there at launch")
    func importStartsWhenAccountAppears() async throws {
        try makeSavedPost(postID: 1, siteID: 100)
        var hasAccount = false
        let service = service
        let savedPosts = savedPosts
        let store = ReaderSavedPostsStore(
            coreDataStack: contextManager,
            track: { _, _ in },
            makeSession: { _ in
                hasAccount ? .init(userID: 42, service: service, savedPosts: savedPosts, client: nil) : nil
            },
            removeAccountData: { _ in },
            observesAccountChanges: false
        )
        #expect(store.start() == nil)

        hasAccount = true
        #expect(store.isActive)
        await store.start()?.value

        #expect(service.importedSaves.first?.map(\.identity.id) == [1])
        #expect(savedPosts.refreshCount >= 1)
    }

    @Test("Saving a post goes to the account, not Core Data")
    func toggleSaves() async throws {
        let post = try makePost(postID: 5, siteID: 100)

        let store = makeStore()
        let isSaved = try await store.toggleSaved(post)

        #expect(isSaved)
        #expect(service.savedIdentities.map(\.id) == [5])
        #expect(store.isSaved(post) == true)
        #expect(!post.isSavedForLater)
    }

    @Test("Toggling a post the account has saved unsaves it")
    func toggleUnsaves() async throws {
        let post = try makePost(postID: 5, siteID: 100)
        service.savedKeys = [.post(blogId: 100, postId: 5)]

        let store = makeStore()
        let isSaved = try await store.toggleSaved(post)

        #expect(!isSaved)
        #expect(service.unsavedIdentities.map(\.id) == [5])
        #expect(store.isSaved(post) == false)
    }

    @Test("When the account doesn't know a post, this device's saved state decides")
    func toggleFallsBackToCoreData() async throws {
        let post = try makeSavedPost(postID: 5, siteID: 100)
        service.unknownKeys = [.post(blogId: 100, postId: 5)]

        let store = makeStore()
        #expect(store.isSaved(post) == nil)
        #expect(store.isSavedForDisplay(post))

        try await store.toggleSaved(post)

        #expect(service.unsavedIdentities.map(\.id) == [5])
        #expect(service.savedIdentities.isEmpty)
    }

    @Test("A failed save is rethrown")
    func failedSaveIsRethrown() async throws {
        let post = try makePost(postID: 5, siteID: 100)
        service.saveError = URLError(.timedOut)

        let store = makeStore()
        await #expect(throws: URLError.self) {
            try await store.toggleSaved(post)
        }

        #expect(store.isSaved(post) == false)
        #expect(!post.isSavedForLater)
    }

    @Test("Saving a list sends keys in bulk and URLs one at a time")
    func saveList() async throws {
        service.rejectedKeys = [.feedItem(feedItemId: 55)]

        let store = makeStore()
        let result = try await store.save([
            ReaderSavedPostsSyncTests.identity(id: 1, siteID: 100),
            ReaderSavedPostsSyncTests.feedItem(55),
            ReaderSavedPostsSyncTests.snapshot(url: "https://example.com/page"),
            ReaderSavedPostsSyncTests.identity(id: 0, siteID: nil)
        ])

        #expect(result == .init(saved: 2, failed: 1, unsaveable: 1))
        #expect(service.bulkImports == [[.post(blogId: 100, postId: 1), .feedItem(feedItemId: 55)]])
        #expect(service.savedURLs == ["https://example.com/page"])
    }

    @Test("Saving a list skips posts the account has, and refreshes the saved list")
    func saveListSkipsSavedPostsAndRefreshes() async throws {
        service.savedKeys = [.post(blogId: 100, postId: 7)]

        let store = makeStore()
        await store.start()?.value
        let refreshesBefore = savedPosts.refreshCount
        let result = try await store.save([
            ReaderSavedPostsSyncTests.identity(id: 7, siteID: 100),
            ReaderSavedPostsSyncTests.identity(id: 8, siteID: 100)
        ])

        #expect(result == .init(alreadySaved: 1, saved: 1))
        #expect(service.bulkImports == [[.post(blogId: 100, postId: 8)]])
        #expect(savedPosts.refreshCount == refreshesBefore + 1)
    }

    @Test("Saving only posts the account has doesn't refresh the saved list")
    func saveListOfSavedPostsDoesNotRefresh() async throws {
        service.savedKeys = [.post(blogId: 100, postId: 7)]

        let store = makeStore()
        await store.start()?.value
        let refreshesBefore = savedPosts.refreshCount
        let result = try await store.save([ReaderSavedPostsSyncTests.identity(id: 7, siteID: 100)])

        #expect(result == .init(alreadySaved: 1))
        #expect(service.bulkImports.isEmpty)
        #expect(savedPosts.refreshCount == refreshesBefore)
    }

    @Test("Signing out drops the session and deletes the account's data")
    func removeAccountDropsSession() async throws {
        let store = makeStore()
        #expect(store.isActive)
        #expect(service.observer != nil)

        store.removeAccount(userID: 42)

        #expect(removedAccounts == [42])
        #expect(service.observer == nil)
        #expect(sessionsMade == 1)
    }

    @Test("Nothing on screen brings the account back while it's signed out")
    func noSessionWhileSigningOut() async throws {
        let post = try makePost(postID: 5, siteID: 100)
        let store = makeStore(observesAccountChanges: true)
        #expect(store.isActive)

        // A bookmark on screen updates when the session is dropped, while the Core Data account
        // still exists.
        var answersDuringSignOut: [Bool] = []
        let observer = NotificationCenter.default.addObserver(
            forName: .readerSavedPostsDidChange,
            object: nil,
            queue: nil
        ) { _ in
            MainActor.assumeIsolated {
                answersDuringSignOut.append(store.isSavedForDisplay(post))
            }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        store.removeAccount(userID: 42)

        #expect(answersDuringSignOut == [false])
        #expect(!store.isActive)
        #expect(sessionsMade == 1)

        // The account change that follows deleting the account lets the next account in.
        NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        #expect(store.isActive)
        #expect(sessionsMade == 2)
    }

    @Test("Without a WordPress.com account nothing can be saved, and this device's flag is shown")
    func inactiveWithoutAccount() async throws {
        let post = try makeSavedPost(postID: 5, siteID: 100)
        let store = ReaderSavedPostsStore(
            coreDataStack: contextManager,
            track: { _, _ in },
            makeSession: { _ in nil },
            removeAccountData: { _ in },
            observesAccountChanges: false
        )

        #expect(!store.isActive)
        #expect(store.start() == nil)
        #expect(store.savedPosts == nil)
        #expect(store.isSaved(post) == nil)
        #expect(store.isSavedForDisplay(post))
        await #expect(throws: ReaderSavedPostsStore.StoreError.self) {
            try await store.toggleSaved(post)
        }
        #expect(post.isSavedForLater)
    }

    // MARK: - Helpers

    @discardableResult
    private func makePost(
        postID: Int,
        siteID: Int,
        sortRank: Double = 0,
        sortDate: Date = Date()
    ) throws -> ReaderPost {
        let post = contextManager.mainContext.insertNewObject(ofType: ReaderPost.self)
        post.postID = NSNumber(value: postID)
        post.siteID = NSNumber(value: siteID)
        post.postTitle = "Post \(postID)"
        post.sortRank = NSNumber(value: sortRank)
        post.sortDate = sortDate
        try contextManager.mainContext.save()
        return post
    }

    @discardableResult
    private func makeSavedPost(
        postID: Int,
        siteID: Int,
        sortRank: Double = 0,
        sortDate: Date = Date()
    ) throws -> ReaderPost {
        let post = try makePost(postID: postID, siteID: siteID, sortRank: sortRank, sortDate: sortDate)
        post.isSavedForLater = true
        try contextManager.mainContext.save()
        return post
    }
}

@MainActor
private final class StoreRecord {
    var sessionsMade = 0
    var removedAccounts: [Int64] = []
    var tracked: [(event: WPAnalyticsEvent, properties: [AnyHashable: Any])] = []
}

// MARK: - Cache

/// Uses a real `WordPressApiCache` on a temporary file. Nothing here touches the network.
@MainActor
struct ReaderSavedPostsCacheTests {
    private let client = WPComApiClient(authentication: .none)

    @Test("Signing out forgets that the account's saves were imported")
    func removeAccountDeletesTheAccount() async throws {
        let cache = try Self.makeCache()
        let service = try client.makeReaderSavedService(source: .ios, cache: cache, userID: 42)
        #expect(try await !service.importLocalSaves(saves: []).alreadyImported)
        #expect(try await service.importLocalSaves(saves: []).alreadyImported)

        let store = ReaderSavedPostsStore(
            coreDataStack: ContextManager.forTesting(),
            track: { _, _ in },
            makeSession: { _ in .init(userID: 42, service: service, client: nil) },
            removeAccountData: { try cache.removeWordpressComAccount(userId: UInt64($0)) },
            observesAccountChanges: false
        )
        // Not asking whether the store is active: that would start a refresh, which needs the network.
        store.removeAccount(userID: 42)

        let newService = try client.makeReaderSavedService(source: .ios, cache: cache, userID: 42)
        #expect(try await !newService.importLocalSaves(saves: []).alreadyImported)
    }

    @Test("The Saved list reads an empty account from the cache")
    func emptyListFromCache() async throws {
        let cache = try Self.makeCache()
        let service = try client.makeReaderSavedService(source: .ios, cache: cache, userID: 42)
        let viewModel = ReaderSavedPostsViewModel(
            service: service,
            cacheUpdates: cache.databaseUpdatesPublisher(),
            presentError: { _ in }
        )

        await viewModel.reloadFromCache()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.rows.isEmpty)
        #expect(!viewModel.hasMore)
    }

    static func makeCache() throws -> WordPressApiCache {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("reader-saved-\(UUID().uuidString).sqlite")
        let cache = try WordPressApiCache(path: url.path)
        _ = try cache.performMigrations()
        return cache
    }
}

/// Answers like the real service from the keys it's given. Tests run on the main actor, so the
/// unsynchronized state is only touched from there.
final class FakeReaderSavedService: ReaderSavedServiceProtocol, @unchecked Sendable {
    var savedKeys: Set<ReaderSavedKey> = []
    var unknownKeys: Set<ReaderSavedKey> = []
    var rejectedKeys: Set<ReaderSavedBulkKey> = []
    var importError: Error?
    var alreadyImported = false
    /// What the import reports, instead of every save imported.
    var importReport: ReaderSavedImportReport?
    var saveError: Error?
    var unsaveError: Error?

    private(set) var importedSaves: [[ReaderLocalSave]] = []
    private(set) var bulkImports: [[ReaderSavedBulkKey]] = []
    private(set) var savedIdentities: [ReaderPostSaveIdentity] = []
    private(set) var unsavedIdentities: [ReaderPostSaveIdentity] = []
    private(set) var unsavedKeys: [ReaderSavedKey] = []
    private(set) var savedURLs: [String] = []
    private(set) var refreshCount = 0
    private(set) var observer: ReaderSavedObserver?

    func `import`(keys: [ReaderSavedBulkKey]) async throws -> [ReaderSavedBulkResult] {
        bulkImports.append(keys)
        return keys.map { key in
            let isRejected = rejectedKeys.contains(key)
            return ReaderSavedBulkResult(key: key, saved: !isRejected, error: isRejected ? "saved_limit_reached" : nil)
        }
    }

    func importLocalSaves(saves: [ReaderLocalSave]) async throws -> ReaderSavedImportReport {
        importedSaves.append(saves)
        if let importError { throw importError }
        if alreadyImported {
            return ReaderSavedImportReport(alreadyImported: true, imported: 0, rejected: [], unsaveable: 0)
        }
        return importReport
            ?? ReaderSavedImportReport(
                alreadyImported: false,
                imported: UInt64(saves.count),
                rejected: [],
                unsaveable: 0
            )
    }

    func listPosts(params: ReaderSavedPostsParams) async throws -> ReaderSavedPostsResponse {
        ReaderSavedPostsResponse(posts: [], nextPageHandle: nil, found: 0)
    }

    func localOnlyKeys() -> [ReaderSavedKey] { [] }

    func recentSaves() -> [ReaderSavedKey] { [] }

    func refresh() async throws {
        refreshCount += 1
    }

    func save(post: ReaderPostSaveIdentity) async throws -> ReaderSavedKey {
        savedIdentities.append(post)
        if let saveError { throw saveError }
        guard let key = post.savedKey else { throw ReaderSavedError.PostCannotBeSaved }
        savedKeys.insert(key)
        return key
    }

    func saveUrl(url: String, pageDetails: ReaderSavedPageDetails?) async throws -> ReaderSavedKey {
        savedURLs.append(url)
        savedKeys.insert(.url(url: url))
        return .url(url: url)
    }

    func savedCount() -> UInt64? { UInt64(savedKeys.count) }

    func savedPosts() -> ReaderSavedPostsCollection {
        // The tests pass their own collection.
        ReaderSavedPostsCollection(noHandle: .init())
    }

    func setObserver(observer: ReaderSavedObserver?) {
        self.observer = observer
    }

    func status(post: ReaderPostSaveIdentity) -> ReaderSavedStatus {
        let keys = post.savedKeys
        if keys.contains(where: savedKeys.contains) { return .saved }
        if keys.contains(where: unknownKeys.contains) { return .unknown }
        return .notSaved
    }

    func unsave(post: ReaderPostSaveIdentity) async throws {
        unsavedIdentities.append(post)
        if let unsaveError { throw unsaveError }
        for key in post.savedKeys {
            savedKeys.remove(key)
        }
    }

    func unsaveKey(key: ReaderSavedKey) async throws {
        unsavedKeys.append(key)
        if let unsaveError { throw unsaveError }
        savedKeys.remove(key)
    }
}
