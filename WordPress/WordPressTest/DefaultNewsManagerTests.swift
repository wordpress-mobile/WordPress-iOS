import XCTest
@testable import WordPress

final class DefaultNewsManagerTests: XCTestCase {
    private struct Constants {
        static let title = "This is an awesome new feature!"
        static let contextId = "context"
    }

    private var manager: NewsManager?
    private var service: NewsService?

    override func setUp() {
        super.setUp()
        service = LocalNewsService(fileName: "News")
        manager = DefaultNewsManager(service: service!, database: NullMockUserDefaults())
    }

    override func tearDown() {
        manager = nil
        service = nil
        super.tearDown()
    }

    func testManagerReturnsExpectedContent() {
        manager?.load(then: { result in
            switch result {
            case .error:
                XCTFail()
            case .success(let newsItem):
                XCTAssertEqual(newsItem.title, Constants.title)
            }
        })
    }

    func testManagerShouldPresentUI() {
        XCTAssertTrue(manager!.shouldPresentCard(contextId: Identifier(value: Constants.contextId)))
    }
}
