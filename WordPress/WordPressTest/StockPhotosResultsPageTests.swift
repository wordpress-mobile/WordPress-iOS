import XCTest
@testable import WordPress

final class StockPhotosResultsPageTests: XCTestCase {
    private struct Constants {
        static let mockData = [mock(), mock()]
    }

    private static func mock() -> StockPhotosMedia {
        let json = Bundle(for: StockPhotosResultsPageTests.self).url(forResource: "stock-photos-media", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        return try! jsonDecoder.decode(StockPhotosMedia.self, from: data)
    }

    private var subject: StockPhotosResultsPage?

    override func setUp() {
        super.setUp()
        subject = StockPhotosResultsPage(results: Constants.mockData, pageable: StockPhotosPageable.first())
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testEmptyPageDoesNotContainData() {
        let emptyResults = StockPhotosResultsPage.empty()

        let resultsCount = emptyResults.content()?.count

        XCTAssertEqual(resultsCount, 0)
    }

    func testEmptyPageDoesNotProvideNextPageable() {
        let emptyResults = StockPhotosResultsPage.empty()

        XCTAssertNil(emptyResults.nextPageable())
    }

    func testPageContainsDataProvidedInInitializer() {
        let data = subject?.content()

        XCTAssertEqual(data, Constants.mockData)
    }
}
