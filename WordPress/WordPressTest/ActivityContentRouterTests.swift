import XCTest
@testable import WordPress

final class ActivityContentRouterTests: XCTestCase {

    let testData = ActivityLogTestData()
    var testCoordinator: MockContentCoordinator!

    override func setUp() {
        super.setUp()
        testCoordinator = MockContentCoordinator()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testRouteToComment() {
        let commentActivity = getCommentActivity()
        let router = ActivityContentRouter(activity: commentActivity, coordinator: testCoordinator)

        router.routeTo(commentURL)

        XCTAssertTrue(testCoordinator.commentsWasDisplayed)
        XCTAssertEqual(testCoordinator.commentPostID?.intValue, testData.testPostID)
        XCTAssertEqual(testCoordinator.commentSiteID?.intValue, testData.testSiteID)
    }

    func testRouteToPost() {
        let activity = getPostActivity()
        let router = ActivityContentRouter(activity: activity, coordinator: testCoordinator)

        router.routeTo(postURL)

        XCTAssertTrue(testCoordinator.readerWasDisplayed)
        XCTAssertEqual(testCoordinator.readerPostID?.intValue, testData.testPostID)
        XCTAssertEqual(testCoordinator.readerSiteID?.intValue, testData.testSiteID)
    }
}

// MARK: - Helpers

extension ActivityContentRouterTests {
    var postURL: URL {
        return URL(string: testData.testPostUrl)!
    }

    var commentURL: URL {
        return URL(string: testData.testCommentURL)!
    }

    func getCommentActivity() -> FormattableActivity {
        let activity = try! Activity(dictionary: testData.getCommentEventDictionary())
        return FormattableActivity(with: activity)
    }

    func getPostActivity() -> FormattableActivity {
        let activity = try! Activity(dictionary: testData.getPostEventDictionary())
        return FormattableActivity(with: activity)
    }
}
