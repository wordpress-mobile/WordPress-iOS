import XCTest
@testable import WordPress

final class LocalNewsServiceTests: XCTestCase {
    private struct Constants {
        static let title = "This is an awesome new feature!"
        static let content = "This is long form content. Here we explain why this feature is awesome"
        static let url = URL(string: "https://wordpress.com")!
    }

    private var service: NewsService?

    override func setUp() {
        super.setUp()
        service = LocalNewsService(fileName: "News")
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testServiceReturnsExpectedContent() {
        service?.load(then: { result in
            switch result {
            case .error (let error):
                print(error)
                XCTFail()
            case .success(let newsItem):
                XCTAssertEqual(newsItem.title, Constants.title)
            }
        })
    }
}
