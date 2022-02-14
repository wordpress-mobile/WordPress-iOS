import XCTest
import Nimble

@testable import WordPress

class BlogDashboardServiceTests: XCTestCase {
    private var service: BlogDashboardService!
    private var remoteServiceMock: DashboardServiceRemoteMock!
    private var persistenceMock: BlogDashboardPersistenceMock!

    override func setUp() {
        super.setUp()

        remoteServiceMock = DashboardServiceRemoteMock()
        persistenceMock = BlogDashboardPersistenceMock()
        service = BlogDashboardService(managedObjectContext: TestContextManager().newDerivedContext(), remoteService: remoteServiceMock, persistence: persistenceMock)
    }

    func testCallServiceWithCorrectIDAndCards() {
        let expect = expectation(description: "Request the correct ID")

        service.fetch(wpComID: 123456) { _ in
            XCTAssertEqual(self.remoteServiceMock.didCallWithBlogID, 123456)
            XCTAssertEqual(self.remoteServiceMock.didRequestCards, ["posts", "todays_stats"])
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCreateSectionForPosts() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        service.fetch(wpComID: 123456) { snapshot in
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
            XCTAssertTrue(postsCardItem.cellViewModel!["has_published"] as! Bool)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testTodaysStats() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        service.fetch(wpComID: 123456) { snapshot in
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
            XCTAssertEqual(todaysStatsItem.cellViewModel, ["views": 0, "visitors": 0, "likes": 0, "comments": 0])

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testLocalCards() {
        let expect = expectation(description: "Return local cards stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        service.fetch(wpComID: 123456) { snapshot in
            // Quick Actions exists
            let quickActionsSection = snapshot.sectionIdentifiers.filter { $0.id == .quickAction }
            XCTAssertEqual(quickActionsSection.count, 1)

            // The item identifier id is quick actions
            XCTAssertEqual(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.id, .quickActions)

            // It doesn't have a data source
            XCTAssertNil(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.cellViewModel)

            // It doesn't have an entity
            XCTAssertNil(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.entity)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testPersistCardsResponse() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        service.fetch(wpComID: 123456) { snapshot in
            XCTAssertEqual(self.persistenceMock.didCallPersistWithCards,
                           self.dictionary(from: "dashboard-200-with-drafts-and-scheduled.json"))
            XCTAssertEqual(self.persistenceMock.didCallPersistWithWpComID, 123456)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testFetchCardsFromPersistence() {
        persistenceMock.respondWith = dictionary(from: "dashboard-200-with-drafts-and-scheduled.json")!

        let snapshot = service.fetchLocal(wpComID: 123456)

        let postsSection = snapshot.sectionIdentifiers.first(where: { $0.id == .posts })
        XCTAssertNotNil(postsSection)
        XCTAssertEqual(persistenceMock.didCallGetCardsWithWpComID, 123456)
    }

    func dictionary(from file: String) -> NSDictionary? {
        let fileURL: URL = Bundle(for: BlogDashboardServiceTests.self).url(forResource: file, withExtension: nil)!
        let data: Data = try! Data(contentsOf: fileURL)
        return try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
    }
}

// MARK: - Mocks

class DashboardServiceRemoteMock: DashboardServiceRemote {
    enum Response: String {
        case withDraftAndSchedulePosts = "dashboard-200-with-drafts-and-scheduled.json"
        case withDraftsOnly = "dashboard-200-with-drafts-only.json"
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
            success([:])
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
    var respondWith: NSDictionary = [:]

    override func getCards(for wpComID: Int) -> NSDictionary? {
        didCallGetCardsWithWpComID = wpComID

        return respondWith
    }
}
