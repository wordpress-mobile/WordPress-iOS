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
}

class DashboardServiceRemoteMock: DashboardServiceRemote {
    var didCallWithBlogID: Int?
    var didRequestCards: [String]?

    override func fetch(cards: [String], forBlogID blogID: Int, success: @escaping (NSDictionary) -> Void, failure: @escaping (Error) -> Void) {
        didCallWithBlogID = blogID
        didRequestCards = cards
        success([:])
    }
}
