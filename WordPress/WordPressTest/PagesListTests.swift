import Foundation
import XCTest

@testable import WordPress

class PagesListTests: CoreDataTestCase {

    var algorithm: ([Page]) -> [Page] = { $0.hierarchySort() }

    func testFlatList() throws {
        let total = 1000
        let pages = (1...total).map { id in
            let page = PageBuilder(mainContext).build()
            page.postID = NSNumber(value: id)
            return page
        }
        let pagesList = algorithm(pages)
        try XCTAssertEqual(pagesList.map { try XCTUnwrap($0.postID).intValue }, (1...total).map { $0 })
    }

    func testOneNestedList() throws {
        let total = 1000
        var pages = [Page]()
        for index in (0..<total) {
            let page = PageBuilder(mainContext).build()
            page.postID = NSNumber(value: index + 1)
            pages.append(page)

            if index > 0 {
                let previous = pages[index - 1]
                page.parentID = previous.postID
            }
        }

        let pagesList = algorithm(pages)
        try XCTAssertEqual(pagesList.map { try XCTUnwrap($0.postID).intValue }, (1...total).map { $0 })
    }

    func testManyNestedLists() throws {
        var pages = [Page]()
        pages.append(contentsOf: parentPage(postID: 10, childrenCount: 1))
        pages.append(contentsOf: parentPage(postID: 20, childrenCount: 2))
        pages.append(contentsOf: parentPage(postID: 30, childrenCount: 3))

        let pagesList = algorithm(pages)
        try XCTAssertEqual(pagesList.map { try XCTUnwrap($0.postID).intValue }, [10, 11, 20, 21, 22, 30, 31, 32, 33])
    }

    private func parentPage(postID: Int, childrenCount: Int) -> [Page] {
        let parent = PageBuilder(mainContext).build()
        parent.postID = NSNumber(value: postID)

        let children = (0..<childrenCount).map { index in
            let child = PageBuilder(mainContext).build()
            child.postID = NSNumber(value: postID + index + 1)
            child.parentID = parent.postID
            return child
        }

        return [parent] + children
    }
}
