import XCTest
@testable import WordPress

final class LocalNewsServiceTests: XCTestCase {
    private struct Constants {
        static let content = "😳🎉"
    }

    private var service: NewsService?

    override func setUp() {
        super.setUp()
        service = LocalNewsService(fileName: Constants.content)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testServiceReturnsExpectedContent() {
        service?.load(then: { result in
            switch result {
            case .error:
                XCTFail()
            case .success(let newsItem):
                XCTAssertEqual(newsItem.content, Constants.content)
            }
        })
    }
}
