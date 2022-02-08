import XCTest
import Nimble

@testable import WordPress

class BlogDashboardServiceTests: XCTestCase {
    private var service: BlogDashboardService!
    private var remoteServiceMock: DashboardServiceRemoteMock!

    override func setUp() {
        super.setUp()

        remoteServiceMock = DashboardServiceRemoteMock()
        service = BlogDashboardService(managedObjectContext: TestContextManager().newDerivedContext(), remoteService: remoteServiceMock)
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

    func testCreateSectionForDraftsAndScheduled() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        service.fetch(wpComID: 123456) { snapshot in
            // Drafts and Scheduled section exists
            let draftsSection = snapshot.sectionIdentifiers.first(where: { $0.subtype == "draft" })
            let scheduledSection = snapshot.sectionIdentifiers.first(where: { $0.subtype == "scheduled" })
            XCTAssertNotNil(draftsSection)
            XCTAssertNotNil(scheduledSection)

            // The id is posts
            XCTAssertEqual(snapshot.itemIdentifiers(inSection: draftsSection!).first?.id, .posts)

            // For Drafts section
            XCTAssertFalse(snapshot.itemIdentifiers(inSection: draftsSection!).first?.cellViewModel?["show_scheduled"] as! Bool)
            XCTAssertTrue(snapshot.itemIdentifiers(inSection: draftsSection!).first?.cellViewModel?["show_drafts"] as! Bool)

            // For Scheduled section
            XCTAssertFalse(snapshot.itemIdentifiers(inSection: scheduledSection!).first?.cellViewModel?["show_drafts"] as! Bool)
            XCTAssertTrue(snapshot.itemIdentifiers(inSection: scheduledSection!).first?.cellViewModel?["show_scheduled"] as! Bool)
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCreateSectionForDraftOnly() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftsOnly

        service.fetch(wpComID: 123456) { snapshot in
            // Drafts and Scheduled section exists
            let draftsSection = snapshot.sectionIdentifiers.filter { $0.id == "posts" && $0.subtype == nil }
            XCTAssertEqual(draftsSection.count, 1)

            // The item identifier id is posts
            XCTAssertEqual(snapshot.itemIdentifiers(inSection: draftsSection.first!).first?.id, .posts)

            // For Drafts section, showScheduled is nil
            XCTAssertFalse(snapshot.itemIdentifiers(inSection: draftsSection.first!).first?.cellViewModel?["show_scheduled"] as! Bool)

            // For Drafts section, scheduled has 1 post
            XCTAssertTrue(snapshot.itemIdentifiers(inSection: draftsSection.first!).first?.cellViewModel?["show_drafts"] as! Bool)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testTodaysStats() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        service.fetch(wpComID: 123456) { snapshot in
            // Drafts and Scheduled section exists
            let todaysStatsSection = snapshot.sectionIdentifiers.filter { $0.id == "todays_stats" }
            XCTAssertEqual(todaysStatsSection.count, 1)

            // The item identifier id is todaysStats
            XCTAssertEqual(snapshot.itemIdentifiers(inSection: todaysStatsSection.first!).first?.id, .todaysStats)

            // Todays Stats has the correct data source
            XCTAssertEqual(snapshot.itemIdentifiers(inSection: todaysStatsSection.first!).first?.cellViewModel, ["views": 0, "visitors": 0, "likes": 0, "comments": 0])

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testLocalCards() {
        let expect = expectation(description: "Return local cards stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        service.fetch(wpComID: 123456) { snapshot in
            // Quick Actions exists
            let quickActionsSection = snapshot.sectionIdentifiers.filter { $0.id == "quickActions" }
            XCTAssertEqual(quickActionsSection.count, 1)

            // The item identifier id is quick actions
            XCTAssertEqual(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.id, .quickActions)

            // It doesn't have a data source
            XCTAssertNil(snapshot.itemIdentifiers(inSection: quickActionsSection.first!).first?.cellViewModel)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
}

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
