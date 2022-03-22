import XCTest
import Nimble

@testable import WordPress

/// This test stuite is clashing with other tests
/// Specifically:
/// - [BlogJetpackTest testJetpackSetupDoesntReplaceDotcomAccount]
/// - CommentServiceTests.testFailingFetchCommentLikesShouldCallFailureBlock()
///
/// We weren't able to figure out why but it seems a race condition + Core data
/// For now, renaming the suite to change the execution order solves the issue.
class ZBlogDashboardServiceTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    private var service: BlogDashboardService!
    private var remoteServiceMock: DashboardServiceRemoteMock!
    private var persistenceMock: BlogDashboardPersistenceMock!

    private let wpComID = 123456

    override func setUp() {
        super.setUp()

        remoteServiceMock = DashboardServiceRemoteMock()
        persistenceMock = BlogDashboardPersistenceMock()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
        service = BlogDashboardService(managedObjectContext: context, remoteService: remoteServiceMock, persistence: persistenceMock)
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        contextManager = nil
    }

    func testCallServiceWithCorrectIDAndCards() {
        let expect = expectation(description: "Request the correct ID")

        let blog = newTestBlog(id: wpComID, context: context)

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

        let blog = newTestBlog(id: wpComID, context: context)

        service.fetch(blog: blog) { snapshot in
            let postsSection = snapshot.sectionIdentifiers.first(where: { $0.id == .posts })
            let postsCardItem: DashboardCardModel = snapshot.itemIdentifiers(inSection: postsSection!).first!

            // Posts section exists
            XCTAssertNotNil(postsSection)

            // Item id is posts
            XCTAssertEqual(postsCardItem.id, .posts)

            // Has published is `true`
            XCTAssertTrue(postsCardItem.apiResponse!.posts!.hasPublished!)

            // 3 scheduled item
            XCTAssertEqual(postsCardItem.apiResponse!.posts!.draft!.count, 3)

            // 1 scheduled item
            XCTAssertEqual(postsCardItem.apiResponse!.posts!.scheduled!.count, 1)

            // cell view model is a `NSDictionary`
            XCTAssertTrue(postsCardItem.hashableDictionary!["has_published"] as! Bool)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testTodaysStats() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: context)

        service.fetch(blog: blog) { snapshot in
            let todaysStatsSection = snapshot.sectionIdentifiers.first(where: { $0.id == .todaysStats })
            let todaysStatsItem: DashboardCardModel = snapshot.itemIdentifiers(inSection: todaysStatsSection!).first!

            // Todays stats section exists
            XCTAssertNotNil(todaysStatsSection)

            // The item identifier id is todaysStats
            XCTAssertEqual(todaysStatsItem.id, .todaysStats)

            // Entity has the correct values
            XCTAssertEqual(todaysStatsItem.apiResponse!.todaysStats!.views, 0)
            XCTAssertEqual(todaysStatsItem.apiResponse!.todaysStats!.visitors, 0)
            XCTAssertEqual(todaysStatsItem.apiResponse!.todaysStats!.likes, 0)
            XCTAssertEqual(todaysStatsItem.apiResponse!.todaysStats!.comments, 0)

            // Todays Stats has the correct NSDictionary
            XCTAssertEqual(todaysStatsItem.hashableDictionary, ["views": 0, "visitors": 0, "likes": 0, "comments": 0])

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testLocalCards() {
        let expect = expectation(description: "Return local cards stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: context)

        service.fetch(blog: blog) { snapshot in
            // Quick Actions exists
            let quickActionsSection = snapshot.sectionIdentifiers.filter { $0.id == .quickActions }
            XCTAssertEqual(quickActionsSection.count, 1)

            // The item identifier id is quick actions
            XCTAssertEqual(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.id, .quickActions)

            // It doesn't have an api response dictionary
            XCTAssertNil(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.hashableDictionary)

            // It doesn't have an api response entity
            XCTAssertNil(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.apiResponse)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testPersistCardsResponse() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: context)

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

        let blog = newTestBlog(id: wpComID, context: context)

        let snapshot = service.fetchLocal(blog: blog)

        let postsSection = snapshot.sectionIdentifiers.first(where: { $0.id == .posts })
        XCTAssertNotNil(postsSection)
        XCTAssertEqual(persistenceMock.didCallGetCardsWithWpComID, wpComID)
    }

    // MARK: - Ghost cards

    /// Ghost cards shouldn't be displayed when parsing the API response
    ///
    func testDontReturnGhostCardsWhenFetchingFromTheAPI() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts
        let blog = newTestBlog(id: 10, context: context)

        service.fetch(blog: blog) { snapshot in
            let ghostSection = snapshot.sectionIdentifiers.first(where: { $0.id == .ghost })
            XCTAssertNil(ghostSection)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    /// Ghost cards shouldn't be displayed when parsing the cached data
    ///
    func testDontReturnGhostCardsWhenFetchingFromCachedData() {
        persistenceMock.respondWith = dictionary(from: "dashboard-200-with-drafts-and-scheduled.json")!
        let blog = newTestBlog(id: 11, context: context)

        let snapshot = service.fetchLocal(blog: blog)

        let ghostSection = snapshot.sectionIdentifiers.first(where: { $0.id == .ghost })
        XCTAssertNil(ghostSection)
    }

    /// Ghost cards SHOULD be displayed when there are no cached data
    /// and the response didn't came from the API.
    ///
    func testReturnGhostCardsWhenNoCachedData() {
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 12, context: context)

        let snapshot = service.fetchLocal(blog: blog)

        let ghostSection = snapshot.sectionIdentifiers.first(where: { $0.id == .ghost })
        XCTAssertNotNil(ghostSection)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: ghostSection!).count, 1)
    }

    // MARK: - Error card

    /// If the first time load fails, show a failure card
    ///
    func testShowErrorCardWhenFailingToLoad() {
        let expect = expectation(description: "Show error card")
        remoteServiceMock.respondWith = .error
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 13, context: context)

        service.fetch(blog: blog) { _ in } failure: { snapshot in
            let failureSection = snapshot?.sectionIdentifiers.first(where: { $0.id == .failure })
            XCTAssertNotNil(failureSection)

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
        let blog = newTestBlog(id: 14, context: context)

        /// Call it once and fails
        service.fetch(blog: blog) { _ in } failure: { snapshot in

            self.remoteServiceMock.respondWith = .withDraftAndSchedulePosts
            /// Call again and succeeds
            self.service.fetch(blog: blog) { snapshot in
                let failureSection = snapshot.sectionIdentifiers.first(where: { $0.id == .failure })
                XCTAssertNil(failureSection)

                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func dictionary(from file: String) -> NSDictionary? {
        let fileURL: URL = Bundle(for: ZBlogDashboardServiceTests.self).url(forResource: file, withExtension: nil)!
        let data: Data = try! Data(contentsOf: fileURL)
        return try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
    }

    private func newTestBlog(id: Int, context: NSManagedObjectContext) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = id as NSNumber
        return blog
    }
}

// MARK: - Mocks

class DashboardServiceRemoteMock: DashboardServiceRemote {
    enum Response: String {
        case withDraftAndSchedulePosts = "dashboard-200-with-drafts-and-scheduled.json"
        case withDraftsOnly = "dashboard-200-with-drafts-only.json"
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

        if let fileURL: URL = Bundle(for: ZBlogDashboardServiceTests.self).url(forResource: respondWith.rawValue, withExtension: nil),
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
