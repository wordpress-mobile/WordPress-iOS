import XCTest
@testable import WordPress

class PostListFilterTests: XCTestCase {

    func testSortDescriptorForPublished() {
        let filter = PostListFilter.publishedFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "date_created_gmt")
        XCTAssertEqual(descriptors[0].ascending, false)
    }


    func testSortDescriptorForDrafs() {
        let filter = PostListFilter.draftFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "dateModified")
        XCTAssertEqual(descriptors[0].ascending, false)
    }

    func testSortDescriptorForScheduled() {
        let filter = PostListFilter.scheduledFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "date_created_gmt")
        XCTAssertEqual(descriptors[0].ascending, true)
    }

    func testSortDescriptorForTrashed() {
        let filter = PostListFilter.trashedFilter()
        let descriptors = filter.sortDescriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors[0].key, "date_created_gmt")
        XCTAssertEqual(descriptors[0].ascending, false)
    }

    func testSectionIdentifiersMatchSortDescriptors() {
        // Every filter must use the same field as the base for the sort
        // descriptor and the sectionIdentifier.
        //
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/6476 for
        // more background on the issue.
        //
        // This doesn't test anything that the above tests haven't tested before
        // in theory, but is added as a safeguard, in case we add new filters.
        for filter in PostListFilter.postListFilters() {
            let descriptors = filter.sortDescriptors
            XCTAssertEqual(descriptors.count, 1)
            XCTAssertEqual(descriptors[0].key, filter.sortField.keyPath)
        }
    }
}
