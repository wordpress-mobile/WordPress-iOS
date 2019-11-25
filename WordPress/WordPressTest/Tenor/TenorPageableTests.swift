import XCTest
@testable import WordPress

class TenorPageableTests: XCTestCase {

    func testTonerResponsePaging() {
        let firstPage = TenorPageable.first()
        XCTAssertEqual(firstPage.pageIndex, 0, "First page should have 0 offset")

        let lastPage = TenorPageable(nextOffset: 0)
        XCTAssertNil(lastPage?.next, "Should not go beyond the last page")
    }

}
