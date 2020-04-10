
@testable import WordPress
import XCTest

final class TenorResultsPageTests: XCTestCase {
    private struct Constants {
        static let mockResults = TenorMockDataHelper.mockMediaList
    }

    private var resultsPage: TenorResultsPage?

    override func setUp() {
        super.setUp()

        resultsPage = TenorResultsPage(results: Constants.mockResults, pageable: TenorPageable.first())
    }

    override func tearDown() {
        resultsPage = nil
        super.tearDown()
    }

    func testEmptyPageDoesNotHaveData() {
        let emptyResults = TenorResultsPage.empty()

        let resultsCount = emptyResults.content()?.count

        XCTAssertEqual(resultsCount, 0)
    }

    func testEmptyPageHasNilNextPageable() {
        let emptyResults = TenorResultsPage.empty()

        XCTAssertNil(emptyResults.nextPageable())
    }

    func testPageHasDataAsInitialized() {
        let data = resultsPage?.content()

        XCTAssertEqual(data, Constants.mockResults)
    }
}
