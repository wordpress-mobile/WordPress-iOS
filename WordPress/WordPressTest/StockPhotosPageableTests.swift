import XCTest
@testable import WordPress

final class StockPhotosPageableTests: XCTestCase {
    private var pageable: StockPhotosPageable?

    private struct Constants {
        static let itemsPerPage = 10
        static let pageHandle = 0
    }

    override func setUp() {
        super.setUp()
        pageable = StockPhotosPageable(itemsPerPage: Constants.itemsPerPage, pageHandle: Constants.pageHandle)
    }

    override func tearDown() {
        pageable = nil
        super.tearDown()
    }

    func testItemsPerPageIsNotMutated() {
        XCTAssertEqual(pageable?.itemsPerPage, Constants.itemsPerPage)
    }

    func testPageHandleIsNotMutated() {
        XCTAssertEqual(pageable?.pageHandle, Constants.pageHandle)
    }

    func testPageSizeReturnsExpectedValue() {
        XCTAssertEqual(pageable?.pageSize, Constants.itemsPerPage)
    }

    func testPageIndexReturnsExpectedValue() {
        XCTAssertEqual(pageable?.pageIndex, Constants.pageHandle)
    }

    func testFirstPageableReturnsExpectedItemsPerPage() {
        let firstPageable = StockPhotosPageable.first()

        XCTAssertEqual(firstPageable.pageSize, StockPhotosPageable.defaultPageSize)
    }

    func testFirstPageableReturnsExpectedPageSize() {
        let firstPageable = StockPhotosPageable.first()

        XCTAssertEqual(firstPageable.pageIndex, StockPhotosPageable.defaultPageIndex)
    }

    func testPageableCanBeParsedFromJSON() {
        let json = Bundle(for: StockPhotosPageableTests.self).url(forResource: "stock-photos-pageable", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        let subject = try! jsonDecoder.decode(StockPhotosPageable.self, from: data)

        XCTAssertEqual(subject.pageIndex, 0)
    }

    func testPageableWithPageHandleZeroDoesNotHaveNextPageable() {
        let subject = StockPhotosPageable(itemsPerPage: 10, pageHandle: 0)
        XCTAssertNil(subject.next())
    }

    func testPageableWithPageHandleNonZeroDoesHaveNextPageable() {
        let subject = StockPhotosPageable(itemsPerPage: 10, pageHandle: 1)
        XCTAssertNotNil(subject.next())
    }
}
