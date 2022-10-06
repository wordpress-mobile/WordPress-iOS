import XCTest
import Nimble

@testable import WordPress

class BlogDashboardServiceTests: CoreDataTestCase {
    private var context: NSManagedObjectContext!

    private var service: BlogDashboardService!
    private var remoteServiceMock: DashboardServiceRemoteMock!
    private var persistenceMock: BlogDashboardPersistenceMock!
    private var postsParserMock: BlogDashboardPostsParserMock!

    private let wpComID = 123456

    override func setUp() {
        super.setUp()

        remoteServiceMock = DashboardServiceRemoteMock()
        persistenceMock = BlogDashboardPersistenceMock()
        postsParserMock = BlogDashboardPostsParserMock(managedObjectContext: mainContext)
        service = BlogDashboardService(managedObjectContext: mainContext, remoteService: remoteServiceMock, persistence: persistenceMock, postsParser: postsParserMock)
    }

    override func tearDown() {
        super.tearDown()
        context = nil
    }

    func testCallServiceWithCorrectIDAndCards() {
        let expect = expectation(description: "Request the correct ID")

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { _ in
            XCTAssertEqual(self.remoteServiceMock.didCallWithBlogID, self.wpComID)
            XCTAssertEqual(self.remoteServiceMock.didRequestCards, ["todays_stats", "posts"])
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCreateSectionForPosts() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let draftPostsCardItem = cards.first(where: {$0.cardType == .draftPosts})
            let scheduledPostsCardItem = cards.first(where: {$0.cardType == .scheduledPosts})

            // Posts section exists
            XCTAssertNotNil(draftPostsCardItem)
            XCTAssertNotNil(scheduledPostsCardItem)

            // Has published is `true`
            XCTAssertTrue(draftPostsCardItem!.apiResponse!.posts!.hasPublished!)

            // 3 scheduled item
            XCTAssertEqual(draftPostsCardItem!.apiResponse!.posts!.draft!.count, 3)

            // 1 scheduled item
            XCTAssertEqual(draftPostsCardItem!.apiResponse!.posts!.scheduled!.count, 1)

            // Has published is `true`
            XCTAssertTrue(scheduledPostsCardItem!.apiResponse!.posts!.hasPublished!)

            // 3 scheduled item
            XCTAssertEqual(scheduledPostsCardItem!.apiResponse!.posts!.draft!.count, 3)

            // 1 scheduled item
            XCTAssertEqual(scheduledPostsCardItem!.apiResponse!.posts!.scheduled!.count, 1)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testTodaysStats() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let todaysStatsItem = cards.first(where: {$0.cardType == .todaysStats})

            // Todays stats section exists
            XCTAssertNotNil(todaysStatsItem)

            // Entity has the correct values
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.views, 0)
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.visitors, 0)
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.likes, 0)
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.comments, 0)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testPersistCardsResponse() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { snapshot in
            XCTAssertEqual(self.persistenceMock.didCallPersistWithCards,
                           self.dictionary(from: "dashboard-200-with-drafts-and-scheduled.json"))
            XCTAssertEqual(self.persistenceMock.didCallPersistWithWpComID, self.wpComID)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testFetchCardsFromPersistence() {
        persistenceMock.respondWith = dictionary(from: "dashboard-200-with-drafts-and-scheduled.json")!

        let blog = newTestBlog(id: wpComID, context: mainContext)

        let cards = service.fetchLocal(blog: blog)

        let hasDrafts = cards.contains(where: {$0.cardType == .draftPosts})
        let hasScheduled = cards.contains(where: {$0.cardType == .scheduledPosts})
        XCTAssertTrue(hasDrafts)
        XCTAssertTrue(hasScheduled)
        XCTAssertEqual(persistenceMock.didCallGetCardsWithWpComID, wpComID)
    }

    // MARK: - Ghost cards

    /// Ghost cards shouldn't be displayed when parsing the API response
    ///
    func testDontReturnGhostCardsWhenFetchingFromTheAPI() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts
        let blog = newTestBlog(id: 10, context: mainContext)

        service.fetch(blog: blog) { cards in
            let hasGhost = cards.contains(where: {$0.cardType == .ghost})
            XCTAssertFalse(hasGhost)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    /// Ghost cards shouldn't be displayed when parsing the cached data
    ///
    func testDontReturnGhostCardsWhenFetchingFromCachedData() {
        persistenceMock.respondWith = dictionary(from: "dashboard-200-with-drafts-and-scheduled.json")!
        let blog = newTestBlog(id: 11, context: mainContext)

        let cards = service.fetchLocal(blog: blog)

        let hasGhost = cards.contains(where: {$0.cardType == .ghost})
        XCTAssertFalse(hasGhost)
    }

    /// Ghost cards SHOULD be displayed when there are no cached data
    /// and the response didn't came from the API.
    ///
    func testReturnGhostCardsWhenNoCachedData() {
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 12, context: mainContext)

        let cards = service.fetchLocal(blog: blog)

        let ghostCards = cards.filter({$0.cardType == .ghost})
        XCTAssertEqual(ghostCards.count, 1)
    }

    // MARK: - Error card

    /// If the first time load fails, show a failure card
    ///
    func testShowErrorCardWhenFailingToLoad() {
        let expect = expectation(description: "Show error card")
        remoteServiceMock.respondWith = .error
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 13, context: mainContext)

        service.fetch(blog: blog) { _ in } failure: { cards in
            let hasError = cards.contains(where: {$0.cardType == .failure})
            XCTAssertTrue(hasError)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    /// If the first time load fails, but a subsequent try
    /// succeeds, don't show the failure card
    ///
    func testNotShowErrorCardAfterFailureButThenSuccess() {
        let expect = expectation(description: "Show error card")
        remoteServiceMock.respondWith = .error
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 14, context: mainContext)

        /// Call it once and fails
        service.fetch(blog: blog) { _ in } failure: { cards in

            self.remoteServiceMock.respondWith = .withDraftAndSchedulePosts
            /// Call again and succeeds
            self.service.fetch(blog: blog) { cards in
                let hasError = cards.contains(where: {$0.cardType == .failure})
                XCTAssertFalse(hasError)

                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Local post content

    /// We might run into the case where the API returns that
    /// there are no posts, but the user has local content.
    /// In this case the response is changed to take into account
    /// local content.
    func testReturnPostsCorrectlyBasedOnLocalContent() {
        let expect = expectation(description: "Return local posts")
        remoteServiceMock.respondWith = .withoutPosts
        postsParserMock.hasDraftsAndScheduled = true

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let hasDrafts = cards.contains(where: {$0.cardType == .draftPosts})
            let hasScheduled = cards.contains(where: {$0.cardType == .scheduledPosts})
            XCTAssertTrue(hasDrafts)
            XCTAssertTrue(hasScheduled)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func dictionary(from file: String) -> NSDictionary? {
        let fileURL: URL = Bundle(for: BlogDashboardServiceTests.self).url(forResource: file, withExtension: nil)!
        let data: Data = try! Data(contentsOf: fileURL)
        return try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
    }

    private func newTestBlog(id: Int, context: NSManagedObjectContext) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.dotComID = id as NSNumber
        return blog
    }
}

// MARK: - Mocks

class DashboardServiceRemoteMock: DashboardServiceRemote {
    enum Response: String {
        case withDraftAndSchedulePosts = "dashboard-200-with-drafts-and-scheduled.json"
        case withDraftsOnly = "dashboard-200-with-drafts-only.json"
        case withoutPosts = "dashboard-200-without-posts.json"
        case error = "error"
    }

    enum Errors: Error {
        case unknown
    }

    var respondWith: Response = .withDraftAndSchedulePosts

    var didCallWithBlogID: Int?
    var didRequestCards: [String]?

    override func fetch(cards: [String], forBlogID blogID: Int, success: @escaping (NSDictionary) -> Void, failure: @escaping (Error) -> Void) {
        didCallWithBlogID = blogID
        didRequestCards = cards

        if let fileURL: URL = Bundle(for: BlogDashboardServiceTests.self).url(forResource: respondWith.rawValue, withExtension: nil),
        let data: Data = try? Data(contentsOf: fileURL),
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject {
            success(jsonObject as! NSDictionary)
        } else {
            failure(Errors.unknown)
        }
    }
}

class BlogDashboardPersistenceMock: BlogDashboardPersistence {
    var didCallPersistWithCards: NSDictionary?
    var didCallPersistWithWpComID: Int?

    override func persist(cards: NSDictionary, for wpComID: Int) {
        didCallPersistWithCards = cards
        didCallPersistWithWpComID = wpComID
    }

    var didCallGetCardsWithWpComID: Int?
    var respondWith: NSDictionary? = [:]

    override func getCards(for wpComID: Int) -> NSDictionary? {
        didCallGetCardsWithWpComID = wpComID

        return respondWith
    }
}

class BlogDashboardPostsParserMock: BlogDashboardPostsParser {
    var hasDraftsAndScheduled = false

    override func parse(_ postsDictionary: NSDictionary, for blog: Blog) -> NSDictionary {
        guard hasDraftsAndScheduled else {
            return postsDictionary
        }

        return ["has_published": false, "draft": [[:]], "scheduled": [[:]]]
    }
}
