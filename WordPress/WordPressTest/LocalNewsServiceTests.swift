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
        let testBundle = Bundle(for: type(of: self))
        let mockFilePath = testBundle.path(forResource: "News", ofType: "strings")
        service = LocalNewsService(filePath: mockFilePath)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testServiceReturnsExpectedContent() {
        service?.load(then: { result in
            switch result {
            case .failure(let error):
                print(error)
                XCTFail()
            case .success(let newsItem):
                XCTAssertEqual(newsItem.title, Constants.title)
            }
        })
    }

    func testServiceReturnsErrorIfStringsFileIsBadFormed() {
        let testBundle = Bundle(for: type(of: self))
        let mockFilePath = testBundle.path(forResource: "NewsBadFormed", ofType: "strings")
        let badFormedService = LocalNewsService(filePath: mockFilePath)

        badFormedService.load(then: { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
            case .success:
                XCTFail("Bad formed news file")
            }
        })
    }
}
