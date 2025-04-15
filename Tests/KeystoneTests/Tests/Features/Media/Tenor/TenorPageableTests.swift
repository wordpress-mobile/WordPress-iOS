
import XCTest

@testable import WordPress

final class TenorPageableTests: XCTestCase {
    private var pageable: TenorPageable?

    private struct Constants {
        static let itemsPerPage = 10
        static let position: String? = nil
        static let currentPageIndex = 0
    }

    override func setUp() {
        super.setUp()
        pageable = TenorPageable(itemsPerPage: Constants.itemsPerPage,
                                 position: Constants.position,
                                 currentPageIndex: 0)
    }

    override func tearDown() {
        pageable = nil
        super.tearDown()
    }

    func testPageableIsNotMutated() {
        XCTAssertEqual(pageable?.itemsPerPage, Constants.itemsPerPage)
        XCTAssertEqual(pageable?.position, Constants.position)
        XCTAssertEqual(pageable?.pageIndex, Constants.currentPageIndex)
    }

    func testFirstPageableReturnsExpectedDefaults() {
        let firstPageable = TenorPageable.first()

        XCTAssertEqual(firstPageable.pageSize, TenorPageable.defaultPageSize)
        XCTAssertEqual(firstPageable.pageIndex, TenorPageable.defaultPageIndex)
        XCTAssertEqual(firstPageable.position, TenorPageable.defaultPosition)
    }

    func testPageableWithNilPositionDoesNotHaveNextPageable() {
        let pageable = TenorPageable(itemsPerPage: 10, position: nil, currentPageIndex: 5)
        XCTAssertNil(pageable.next())
    }
}
