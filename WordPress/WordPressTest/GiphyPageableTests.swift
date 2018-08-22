import XCTest
@testable import WordPress

struct MockGPHPagination: GPHPaginationType {
    let count: Int
    let totalCount: Int
    let offset: Int
}

final class GiphyPageableTests: XCTestCase {
    private var pageable: GiphyPageable?

    private struct Constants {
        static let itemsPerPage = 10
        static let pageHandle = 0
    }

    override func setUp() {
        super.setUp()
        pageable = GiphyPageable(itemsPerPage: Constants.itemsPerPage,
                                 pageHandle: Constants.pageHandle)
    }

    override func tearDown() {
        pageable = nil
        super.tearDown()
    }

    func testPaginationWithZeroCountDoesNotProducePageable() {
        let pagination = MockGPHPagination(count: 0, totalCount: 0, offset: 0)
        let pageable = GiphyPageable(gphPagination: pagination)

        XCTAssertNil(pageable)
    }

    func testPaginationWithRemainingItems() {
        let pagination = MockGPHPagination(count: 10, totalCount: 20, offset: 0)
        let pageable = GiphyPageable(gphPagination: pagination)

        XCTAssertEqual(pageable?.pageHandle, 10)
        XCTAssertEqual(pageable?.itemsPerPage, GiphyPageable.defaultPageSize)
    }

    func testPaginationWithLessThanOnePageRemaining() {
        let pagination = MockGPHPagination(count: 20, totalCount: 30, offset: 0)
        let pageable = GiphyPageable(gphPagination: pagination)

        XCTAssertEqual(pageable?.pageHandle, 20)
        XCTAssertEqual(pageable?.itemsPerPage, GiphyPageable.defaultPageSize)
    }
}
