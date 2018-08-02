import XCTest
@testable import WordPress

final class DefaultNewsManagerTests: XCTestCase {
    private struct Constants {
        static let content = "🤨🤦🏻‍♂️"
    }

    private var manager: NewsManager?
    private var service: NewsService?

    override func setUp() {
        super.setUp()
        service = LocalNewsService(content: Constants.content)
        manager = DefaultNewsManager(service: service!)
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
                XCTAssertEqual(newsItem.content, Constants.content)
            }
        })
    }

    func testManagerShouldPresentUI() {
        XCTAssertTrue(manager!.shouldPresentCard())
    }
}
