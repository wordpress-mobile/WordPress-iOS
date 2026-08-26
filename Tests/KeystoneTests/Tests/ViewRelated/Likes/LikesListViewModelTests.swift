import Foundation
import Testing
import WordPressKit
@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("LikesListViewModel Tests")
struct LikesListViewModelTests {
    private let contextManager = ContextManager.forTesting()
    private let siteID = NSNumber(value: 1)
    private let postID = NSNumber(value: 2)

    // MARK: - First load

    @Test("First load seeds the cached likes from Core Data")
    func firstLoadSeedsCache() {
        // Offline so the remote fetch is skipped and only the cache seed is observed.
        makeNetworkUnavailable()
        let cached = [makeUser(id: 10), makeUser(id: 11)]
        let service = FakePostLikesService()
        service.storedUsers = cached

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 2, service: service)
        viewModel.loadMore()

        #expect(viewModel.users.map { $0.userID } == [10, 11])
        // Offline still surfaces the error state; the view renders it as a
        // footer that keeps the cached likes on screen.
        #expect(viewModel.error != nil)
        #expect(service.getLikesCallCount == 0)
    }

    @Test("Offline with an empty cache surfaces the error state")
    func offlineEmptyCacheShowsError() {
        makeNetworkUnavailable()
        let service = FakePostLikesService()

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 0, service: service)
        viewModel.loadMore()

        #expect(viewModel.users.isEmpty)
        #expect(viewModel.error != nil)
        #expect(viewModel.error?.subtitle == nil)
    }

    // MARK: - Pagination cursor

    @Test("The second page sends the +1s before cursor and the excluded IDs")
    func paginationCursor() {
        makeNetworkAvailable()

        let boundaryDate = Date(timeIntervalSince1970: 1_000_000)
        let page1 = [makeUser(id: 20), makeUser(id: 21, dateLiked: boundaryDate)]
        let page2 = [makeUser(id: 20), makeUser(id: 21, dateLiked: boundaryDate), makeUser(id: 22)]
        let excluded = [makeUser(id: 21, dateLiked: boundaryDate)]

        let service = FakePostLikesService()
        service.totalLikes = 3
        service.pages = [page1, page2]
        service.storedUsersAfter = excluded

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 3, service: service)

        // First page: no cursor, no exclusions, purges existing.
        viewModel.loadMore()
        #expect(service.getLikesCallCount == 1)
        #expect(service.lastBefore == nil)
        #expect(service.lastExcludingIDs == nil)
        #expect(service.lastPurgeExisting == true)

        // Second page: cursor is the boundary date + 1 second, plus the excluded IDs.
        viewModel.loadMore()
        #expect(service.getLikesCallCount == 2)
        #expect(service.lastBefore == expectedBeforeString(from: boundaryDate))
        #expect(service.lastExcludingIDs == [NSNumber(value: 21)])
        #expect(service.lastPurgeExisting == false)
    }

    @Test("No further page is fetched once every like has been loaded")
    func hasMoreGuardStopsPaging() {
        makeNetworkAvailable()

        let page = [makeUser(id: 30), makeUser(id: 31)]
        let service = FakePostLikesService()
        service.totalLikes = 2
        service.pages = [page]

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 2, service: service)
        viewModel.loadMore()
        #expect(service.getLikesCallCount == 1)
        #expect(viewModel.hasMoreLikes == false)

        // Displaying the last row must not trigger another fetch.
        viewModel.loadMoreIfNeeded(displaying: page[1])
        #expect(service.getLikesCallCount == 1)
    }

    // MARK: - Error mapping

    @Test("An authorization-required failure maps to the private-blog message")
    func privateBlogErrorMapping() {
        makeNetworkAvailable()

        let service = FakePostLikesService()
        service.failureError = NSError(
            domain: WordPressComRestApiEndpointError.errorDomain,
            code: WordPressComRestApiErrorCode.authorizationRequired.rawValue
        )

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 0, service: service)
        viewModel.loadMore()

        #expect(viewModel.error != nil)
        #expect(viewModel.error?.subtitle == "You don't have permission to view this private blog.")
    }

    @Test("A generic failure has no subtitle")
    func genericErrorMapping() {
        makeNetworkAvailable()

        let service = FakePostLikesService()
        service.failureError = NSError(domain: "test", code: 500)

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 0, service: service)
        viewModel.loadMore()

        #expect(viewModel.error != nil)
        #expect(viewModel.error?.subtitle == nil)
    }

    @Test("A failed page load keeps the likes that already loaded")
    func failureKeepsLoadedUsers() {
        makeNetworkAvailable()

        let page = [makeUser(id: 40), makeUser(id: 41)]
        let service = FakePostLikesService()
        service.totalLikes = 100
        service.pages = [page]

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 100, service: service)
        viewModel.loadMore()
        #expect(viewModel.users.map { $0.userID } == [40, 41])

        service.failureError = NSError(domain: "test", code: 500)
        viewModel.loadMore()

        #expect(viewModel.users.map { $0.userID } == [40, 41])
        #expect(viewModel.error != nil)
        #expect(!viewModel.isLoadingPage)
    }

    @Test("A successful retry after a failure clears the error")
    func retryAfterFailureClearsError() {
        makeNetworkAvailable()

        let service = FakePostLikesService()
        service.failureError = NSError(domain: "test", code: 500)

        let viewModel = LikesListViewModel(siteID: siteID, postID: postID, totalLikes: 1, service: service)
        viewModel.loadMore()
        #expect(viewModel.error != nil)
        #expect(viewModel.users.isEmpty)

        service.failureError = nil
        service.totalLikes = 1
        service.pages = [[makeUser(id: 50)]]
        viewModel.loadMore()

        #expect(viewModel.error == nil)
        #expect(viewModel.users.map { $0.userID } == [50])
    }

    // MARK: - Helpers

    private func makeUser(id: Int64, dateLiked: Date = Date(timeIntervalSince1970: 0)) -> LikeUser {
        let user = LikeUser(context: contextManager.mainContext)
        user.userID = id
        user.username = "user\(id)"
        user.displayName = "User \(id)"
        user.avatarUrl = ""
        user.likedSiteID = siteID.int64Value
        user.likedPostID = postID.int64Value
        user.dateLiked = dateLiked
        user.dateLikedString = "date-\(id)"
        user.dateFetched = Date(timeIntervalSince1970: 0)
        return user
    }

    /// Replicates the view model's cursor formatting: the boundary date bumped by one
    /// second, formatted "YYYY-MM-DD HH:MM:SS" (no T/Z).
    private func expectedBeforeString(from date: Date) -> String {
        let bumped = Calendar.current.date(byAdding: .second, value: 1, to: date)!
        return ISO8601DateFormatter()
            .string(from: bumped)
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
    }
}

/// A fake `PostLikesServing` that returns queued pages and records the pagination cursor.
/// Nonisolated to match the production `PostService`, which is not main-actor isolated.
private final class FakePostLikesService: PostLikesServing {
    var storedUsers: [LikeUser] = []
    var storedUsersAfter: [LikeUser] = []
    var pages: [[LikeUser]] = []
    var totalLikes = 0
    var failureError: Error?

    private(set) var getLikesCallCount = 0
    private(set) var lastBefore: String?
    private(set) var lastExcludingIDs: [NSNumber]?
    private(set) var lastPurgeExisting: Bool?

    func likeUsersFor(postID: NSNumber, siteID: NSNumber, after: Date?) -> [LikeUser] {
        after == nil ? storedUsers : storedUsersAfter
    }

    func getLikesFor(
        postID: NSNumber,
        siteID: NSNumber,
        count: Int,
        before: String?,
        excludingIDs: [NSNumber]?,
        purgeExisting: Bool,
        success: @escaping (([LikeUser], Int, Int) -> Void),
        failure: @escaping ((Error?) -> Void)
    ) {
        getLikesCallCount += 1
        lastBefore = before
        lastExcludingIDs = excludingIDs
        lastPurgeExisting = purgeExisting

        if let failureError {
            failure(failureError)
            return
        }

        let users = pages.isEmpty ? [] : pages.removeFirst()
        success(users, totalLikes, count)
    }
}
