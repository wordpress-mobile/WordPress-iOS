import Foundation
import CoreData
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressCore
import WordPressData
import WordPressShared

extension Foundation.Notification.Name {
    /// Posted on the main queue when which Reader posts are saved may have changed.
    static let readerSavedPostsDidChange = Foundation.Notification.Name("ReaderSavedPostsDidChange")
}

/// The Reader's saved posts, kept in the WordPress.com account.
///
/// `ReaderSavedService` from wordpress-rs keeps what's saved, and the saved list, in
/// `WordPressApiCache` under the account. It answers whether a post is saved from disk after a
/// relaunch, and the Saved screen reads its list from there. Core Data is only read once per account,
/// to hand this device's saves over to the account. Saving needs a WordPress.com account.
///
/// The Core Data `isSavedForLater` flags stay after the import, as a way back if this has to be
/// rolled back. Nothing writes them any more, and signing out still clears them.
///
/// There's one service per account, shared by every screen, because each instance only knows its
/// own writes: a second one could let a stale refresh undo a change made through the first.
@MainActor
final class ReaderSavedPostsStore {
    static let shared = ReaderSavedPostsStore()

    /// The account's saved posts service, and the account it belongs to.
    struct Session {
        let userID: Int64
        let service: any ReaderSavedServiceProtocol
        /// The saved list, as the Saved screen shows it.
        let savedPosts: any ReaderSavedPostsCollectionProtocol
        /// Kept alive for as long as the service, which uses its delegate.
        let client: AnyObject?

        init(
            userID: Int64,
            service: any ReaderSavedServiceProtocol,
            savedPosts: (any ReaderSavedPostsCollectionProtocol)? = nil,
            client: AnyObject?
        ) {
            self.userID = userID
            self.service = service
            self.savedPosts = savedPosts ?? service.savedPosts()
            self.client = client
        }
    }

    enum StoreError: Error {
        case notActive
    }

    private let coreDataStack: CoreDataStack
    private let track: @MainActor (WPAnalyticsEvent, [AnyHashable: Any]) -> Void
    private let makeSession: @MainActor (CoreDataStack) -> Session?
    private let removeAccountData: @MainActor (Int64) throws -> Void
    private let observer = ChangeObserver()

    private var session: Session?
    private var startTask: Task<Void, Never>?
    /// Set from signing out until the account change notification. The Core Data account is deleted
    /// just after `removeAccount(userID:)`, and a session made for it in between, such as by a
    /// bookmark on screen asking whether its post is saved, would put back what was just deleted.
    private var isRemovingAccount = false
    private var accountObserver: NSObjectProtocol?

    init(
        coreDataStack: CoreDataStack = ContextManager.shared,
        track: @escaping @MainActor (WPAnalyticsEvent, [AnyHashable: Any]) -> Void = {
            WPAnalytics.track($0, properties: $1)
        },
        makeSession: @escaping @MainActor (CoreDataStack) -> Session? = ReaderSavedPostsStore.makeDefaultSession,
        removeAccountData: @escaping @MainActor (Int64) throws -> Void = ReaderSavedPostsStore.removeCachedAccount,
        observesAccountChanges: Bool = true
    ) {
        self.coreDataStack = coreDataStack
        self.track = track
        self.makeSession = makeSession
        self.removeAccountData = removeAccountData

        if observesAccountChanges {
            accountObserver = NotificationCenter.default.addObserver(
                forName: .wpAccountDefaultWordPressComAccountChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.accountChanged()
                }
            }
        }
    }

    deinit {
        if let accountObserver {
            NotificationCenter.default.removeObserver(accountObserver)
        }
    }

    /// Whether there's a WordPress.com account to save to. Without one, posts can't be saved.
    var isActive: Bool {
        loadSessionIfNeeded()
        return session != nil
    }

    /// The account's service, or `nil` without a WordPress.com account.
    var service: (any ReaderSavedServiceProtocol)? {
        isActive ? session?.service : nil
    }

    /// The account's saved list, or `nil` without a WordPress.com account.
    var savedPosts: (any ReaderSavedPostsCollectionProtocol)? {
        isActive ? session?.savedPosts : nil
    }

    /// Hands this device's saves over to the account if it hasn't had them yet, then reloads which
    /// posts are saved. Call at launch.
    ///
    /// This also happens on its own whenever the store first finds the account, such as after
    /// signing in, so it doesn't depend on the account being ready when the app launches.
    ///
    /// - Returns: A task that finishes when both are done, or `nil` when the store isn't active.
    @discardableResult
    func start() -> Task<Void, Never>? {
        if session == nil {
            loadSessionIfNeeded()
            return session == nil ? nil : startTask
        }
        guard let session else { return nil }
        startTask = importAndRefresh(session)
        return startTask
    }

    private func importAndRefresh(_ session: Session) -> Task<Void, Never> {
        Task { @MainActor [coreDataStack, track] in
            let didSend = await Self.importLocalSaves(from: coreDataStack, to: session.service, track: track)
            do {
                if didSend {
                    // An import's posts only reach the saved list through a refresh of the list
                    // itself: refreshing the service reloads the saved keys, not the list.
                    _ = try await session.savedPosts.refresh()
                } else {
                    try await session.service.refresh()
                }
            } catch {
                Loggers.app.error("Reader saved posts: refresh failed: \(String(describing: error))")
            }
        }
    }

    // MARK: - Status

    /// Whether the post is saved in the account, or `nil` when the store isn't active or doesn't know.
    func isSaved(_ post: ReaderPost) -> Bool? {
        guard let service else { return nil }
        switch service.status(post: ReaderSavedPostsSync.identity(for: post)) {
        case .saved: return true
        case .notSaved: return false
        case .unknown: return nil
        }
    }

    /// Whether to show the post as saved: the account's answer when there is one, and otherwise what
    /// this device has.
    func isSavedForDisplay(_ post: ReaderPost) -> Bool {
        isSaved(post) ?? post.isSavedForLater
    }

    // MARK: - Saving

    /// Saves or unsaves the post in the account. The service shows the change straight away, and
    /// takes it back if the request fails.
    ///
    /// - Returns: Whether the post is now saved.
    @discardableResult
    func toggleSaved(_ post: ReaderPost) async throws -> Bool {
        guard let service else {
            throw StoreError.notActive
        }
        let identity = ReaderSavedPostsSync.identity(for: post)
        let willSave = !isSavedForDisplay(post)
        if willSave {
            _ = try await service.save(post: identity)
        } else {
            try await service.unsave(post: identity)
        }
        return willSave
    }

    /// Saves the given posts in the account, such as the ones in an imported file. Unlike the
    /// one-time import of this device's saves, this runs every time it's called.
    func save(_ identities: [ReaderPostSaveIdentity]) async throws -> ReaderSavedPostsSync.SaveResult {
        guard let service else {
            throw StoreError.notActive
        }
        let plan = ReaderSavedPostsSync.importPlan(for: identities)
        var result = ReaderSavedPostsSync.SaveResult(unsaveable: plan.unsaveableCount)

        if !plan.bulkKeys.isEmpty {
            let results = try await service.import(keys: plan.bulkKeys)
            let rejected = ReaderSavedPostsSync.rejectedKeys(plan.bulkKeys, results: results)
            for (key, error) in rejected {
                Loggers.app.warning(
                    "Reader saved posts: save rejected \(String(describing: key)): \(error ?? "unknown")"
                )
            }
            result.saved += plan.bulkKeys.count - rejected.count
            result.failed += rejected.count
        }
        for url in plan.urls {
            do {
                _ = try await service.saveUrl(url: url, pageDetails: nil)
                result.saved += 1
            } catch {
                Loggers.app.warning("Reader saved posts: saving a URL failed: \(String(describing: error))")
                result.failed += 1
            }
        }
        return result
    }

    // MARK: - Importing local saves

    /// Hands the posts saved on this device to the account. The service does it once per account and
    /// remembers that it has, so this sends nothing after the first time it succeeds.
    ///
    /// - Returns: Whether the import sent any posts, so the saved list has new posts to show.
    private static func importLocalSaves(
        from coreDataStack: CoreDataStack,
        to service: any ReaderSavedServiceProtocol,
        track: @MainActor (WPAnalyticsEvent, [AnyHashable: Any]) -> Void
    ) async -> Bool {
        var saveCount = 0
        do {
            let saves = try await coreDataStack.performQuery { context in
                try ReaderSavedPostsSync.fetchLocalSaves(in: context)
            }
            saveCount = saves.count
            let report = try await service.importLocalSaves(saves: saves)
            guard !report.alreadyImported else { return false }
            Loggers.app.info(
                "Reader saved posts: imported \(report.imported), refused \(report.rejected.count), unsaveable \(report.unsaveable)"
            )
            track(
                .readerSavedPostsAccountImport,
                ReaderSavedPostsSync.importProperties(for: report, saveCount: saveCount)
            )
            return report.imported > 0 || !report.rejected.isEmpty
        } catch {
            // The service tries again next time.
            Loggers.app.error("Reader saved posts: import failed: \(String(describing: error))")
            track(
                .readerSavedPostsAccountImport,
                ReaderSavedPostsSync.importProperties(for: error, saveCount: saveCount)
            )
            return false
        }
    }

    // MARK: - Account

    /// Deletes everything kept for the account. Call on sign-out, before the account is deleted.
    func removeAccount(userID: Int64) {
        isRemovingAccount = true
        if session?.userID == userID {
            dropSession()
        }
        guard userID > 0 else { return }
        do {
            try removeAccountData(userID)
        } catch {
            Loggers.app.error("Reader saved posts: removing the account failed: \(String(describing: error))")
        }
    }

    private func loadSessionIfNeeded() {
        guard session == nil, !isRemovingAccount, let session = makeSession(coreDataStack) else { return }
        session.service.setObserver(observer: observer)
        self.session = session
        startTask = importAndRefresh(session)
    }

    private func dropSession() {
        startTask?.cancel()
        startTask = nil
        session?.service.setObserver(observer: nil)
        session = nil
        NotificationCenter.default.post(name: .readerSavedPostsDidChange, object: nil)
    }

    private func accountChanged() {
        isRemovingAccount = false
        dropSession()
        start()
    }

    private static func makeDefaultSession(coreDataStack: CoreDataStack) -> Session? {
        let userID = coreDataStack.performQuery { context in
            (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.userID?.int64Value
        }
        guard let userID, userID > 0 else { return nil }

        let client = WordPressDotComClient(coreDataStack: coreDataStack)
        do {
            let service = try client.api.makeReaderSavedService(
                source: .ios,
                cache: WordPressApiCache.shared,
                userID: UInt64(userID)
            )
            return Session(userID: userID, service: service, client: client)
        } catch {
            Loggers.app.error("Reader saved posts: couldn't create the service: \(String(describing: error))")
            return nil
        }
    }

    private static func removeCachedAccount(userID: Int64) throws {
        try WordPressApiCache.shared.removeWordpressComAccount(userId: UInt64(userID))
    }
}

extension ReaderPost {
    /// Whether to show the post as saved, such as its bookmark icon. With saved posts kept in the
    /// account it's the account's answer, falling back to this device's when that's unknown.
    var isSavedForDisplay: Bool {
        // UI code reads it on the main thread. Anything else gets this device's answer.
        guard Thread.isMainThread else { return isSavedForLater }
        return MainActor.assumeIsolated {
            ReaderSavedPostsStore.shared.isSavedForDisplay(self)
        }
    }
}

/// Turns the service's change callbacks, which come on any thread, into one notification on the main
/// queue per run loop turn.
private final class ChangeObserver: ReaderSavedObserver, @unchecked Sendable {
    private let lock = NSLock()
    private var isScheduled = false

    func savedPostsChanged() {
        lock.lock()
        defer { lock.unlock() }
        guard !isScheduled else { return }
        isScheduled = true

        DispatchQueue.main.async { [self] in
            lock.lock()
            isScheduled = false
            lock.unlock()
            NotificationCenter.default.post(name: .readerSavedPostsDidChange, object: nil)
        }
    }
}

// MARK: - Mapping

/// The parts of saved posts that don't need the network.
enum ReaderSavedPostsSync {

    /// What happened to posts sent with ``ReaderSavedPostsStore/save(_:)``.
    struct SaveResult: Equatable {
        var saved = 0
        /// Posts the server refused, or that failed to send.
        var failed = 0
        /// Posts missing the IDs the API needs.
        var unsaveable = 0
    }

    /// What to send to the server to save a list of posts.
    struct ImportPlan: Equatable {
        /// Keys for the bulk import, newest first.
        var bulkKeys: [ReaderSavedBulkKey] = []
        /// Pages saved by URL, which the bulk import can't take, newest first.
        var urls: [String] = []
        /// Posts missing the IDs the API needs.
        var unsaveableCount = 0
    }

    /// The fields of a post that decide which key it's saved under. They mirror the raw REST fields
    /// (`ID`, `site_ID`, `feed_ID`, `feed_item_ID`, `is_external`, `URL`) that `RemoteReaderPost` reads.
    static func identity(for post: ReaderPost) -> ReaderPostSaveIdentity {
        identity(
            postID: post.postID,
            siteID: post.siteID,
            feedID: post.feedID,
            feedItemID: post.feedItemID,
            isExternal: post.isExternal,
            permaLink: post.permaLink
        )
    }

    /// A negative or missing number becomes `nil`. `BasePost.postID` defaults to -1. A `0` is kept,
    /// because the API treats a post with a `0` site and feed as a page saved by URL.
    static func identity(
        postID: NSNumber?,
        siteID: NSNumber?,
        feedID: NSNumber?,
        feedItemID: NSNumber?,
        isExternal: Bool,
        permaLink: String?
    ) -> ReaderPostSaveIdentity {
        ReaderPostSaveIdentity(
            id: nonNegative(postID) ?? 0,
            siteId: nonNegative(siteID),
            feedId: nonNegative(feedID),
            feedItemId: nonNegative(feedItemID),
            isExternal: isExternal,
            url: permaLink.flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    private static func nonNegative(_ number: NSNumber?) -> UInt64? {
        // `int64Value`, so -1 isn't read as `UInt64.max`.
        guard let value = number?.int64Value, value >= 0 else { return nil }
        return UInt64(value)
    }

    /// What the account needs to know about a post saved on this device. The details besides the
    /// identity are shown if the server refuses the save, which keeps it on this device.
    static func localSave(for post: ReaderPost) -> ReaderLocalSave {
        ReaderLocalSave(
            identity: identity(for: post),
            dateSaved: nil,
            title: post.postTitle?.nonEmptyString(),
            excerpt: post.summary?.nonEmptyString(),
            featuredImage: post.featuredImage?.nonEmptyString(),
            siteName: post.blogName?.nonEmptyString(),
            siteUrl: post.blogURL?.nonEmptyString()
        )
    }

    /// Splits the keys of the given posts, which must be newest first, into the ones the bulk import
    /// takes and the URLs it doesn't.
    static func importPlan(for identities: [ReaderPostSaveIdentity]) -> ImportPlan {
        var plan = ImportPlan()
        var seen = Set<ReaderSavedKey>()
        for identity in identities {
            guard let key = identity.savedKey else {
                plan.unsaveableCount += 1
                continue
            }
            guard seen.insert(key.normalized).inserted else { continue }

            switch key {
            case let .post(blogId, postId):
                plan.bulkKeys.append(.post(blogId: blogId, postId: postId))
            case let .feedItem(feedItemId):
                plan.bulkKeys.append(.feedItem(feedItemId: feedItemId))
            case let .url(url):
                plan.urls.append(url)
            }
        }
        return plan
    }

    /// The keys the server didn't save, with its reason. Results are in the same order as the keys.
    static func rejectedKeys(
        _ keys: [ReaderSavedBulkKey],
        results: [ReaderSavedBulkResult]
    ) -> [(key: ReaderSavedKey, error: String?)] {
        zip(keys, results)
            .compactMap { key, result in
                guard !result.saved else { return nil }
                return (savedKey(for: key), result.error)
            }
    }

    /// A stable string for a key, such as to identify a row.
    static func storageKey(for key: ReaderSavedKey) -> String {
        switch key.normalized {
        case let .post(blogId, postId):
            "post:\(blogId):\(postId)"
        case let .feedItem(feedItemId):
            "feed-item:\(feedItemId)"
        case let .url(url):
            "url:\(url)"
        }
    }

    private static func savedKey(for key: ReaderSavedBulkKey) -> ReaderSavedKey {
        switch key {
        case let .post(blogId, postId): .post(blogId: blogId, postId: postId)
        case let .feedItem(feedItemId): .feedItem(feedItemId: feedItemId)
        }
    }

    // MARK: Analytics

    /// The properties of the event for an import that finished. Counts only: no URLs or titles.
    static func importProperties(for report: ReaderSavedImportReport, saveCount: Int) -> [AnyHashable: Any] {
        [
            "result": "imported",
            "local_saves": saveCount,
            "imported": Int(report.imported),
            "refused": report.rejected.count,
            "unsaveable": Int(report.unsaveable)
        ]
    }

    /// The properties of the event for an import that failed.
    static func importProperties(for error: Error, saveCount: Int) -> [AnyHashable: Any] {
        var properties: [AnyHashable: Any] = [
            "result": "failed",
            "local_saves": saveCount,
            "error_kind": errorKind(for: error)
        ]
        if case let ReaderSavedError.Api(apiError) = error {
            properties["api_error"] = caseName(of: apiError)
        }
        return properties
    }

    static func errorKind(for error: Error) -> String {
        switch error {
        case let error as ReaderSavedError:
            switch error {
            case .Api: "api"
            case .PostCannotBeSaved: "post_cannot_be_saved"
            case .UnexpectedImportResults: "unexpected_import_results"
            case .Database: "database"
            case .StaleLoadMore: "stale_load_more"
            }
        case is URLError: "network"
        case is CocoaError: "core_data"
        default: "other"
        }
    }

    /// The name of an enum case without its values, which can hold URLs or server messages.
    private static func caseName(of value: Any) -> String {
        Mirror(reflecting: value).children.first?.label ?? String(describing: value)
    }

    // MARK: Core Data

    /// The posts saved on this device, in the order the old Saved screen showed them: by
    /// `sortRank`, newest first. The account keeps that order, so the list looks the same after the
    /// import.
    static func fetchLocalSaves(in context: NSManagedObjectContext) throws -> [ReaderLocalSave] {
        let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "isSavedForLater == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "sortRank", ascending: false)]
        return try context.fetch(request).map(localSave(for:))
    }
}
