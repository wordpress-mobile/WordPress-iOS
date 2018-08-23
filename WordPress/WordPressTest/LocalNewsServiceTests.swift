import XCTest
@testable import WordPress

final class LocalNewsServiceTests: XCTestCase {
    private struct Constants {
        static let title = "Howdy Hogwarts!"
        static let content = "I am not trying to be mean, but Ravenclaw is the awesomest team within Hogwarts."
        static let url = URL(string: "http://wordpress.com/me")!
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
