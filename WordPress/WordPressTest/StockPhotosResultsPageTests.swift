import XCTest
@testable import WordPress

final class StockPhotosResultsPageTests: XCTestCase {

    override func setUp() {
        super.setUp()

    }

    override func tearDown() {

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
}
