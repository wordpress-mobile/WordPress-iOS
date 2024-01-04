import Foundation
import XCTest

@testable import WordPress

class PagesListPerformanceTests: CoreDataTestCase {

    var randomID: Int {
        _randomID += 1
        return _randomID
    }

    private var _randomID = 0

    func testFlatList() throws {
        let total = 1000
        let pages = (1...total).map { id in
            let page = PageBuilder(mainContext).build()
            page.postID = NSNumber(value: id)
            return page
        }
        try makeAssertions(pages: pages)
    }

    func testHugeNestedLists() throws {
        var pages = [Page]()
        for _ in 1...100 {
            pages.append(contentsOf: parentPage(childrenCount: 5, additionalLevels: 4))
        }
        // Add orphan pages
        for _ in 1...50 {
            let newPages = parentPage(childrenCount: 5)
            newPages[0].parentID = NSNumber(value: randomID)
            pages.append(contentsOf: newPages)
        }

        try makeAssertions(pages: pages)
    }

    // Measure performance using a page list where somewhat reflects a real-world page list, where some pages whose parent pages are in list.
    func testPerformance() throws {
        // Make sure the total number of pages is about the same as the one in `testWorstPerformance`.
        var pages = [Page]()
        // Add pages whose parents are in the list.
        for _ in 1...100 {
            pages.append(contentsOf: parentPage(childrenCount: 5, additionalLevels: 4))
        }
        // Add pages whose parents are *not* in the list.
        for _ in 1...80 {
            let newPages = parentPage(childrenCount: 5, additionalLevels: 4)
            newPages[0].parentID = NSNumber(value: randomID)
            pages.append(contentsOf: newPages)
        }
        // Use a shuffled list to test performance, which in theory means more iterations in trying to find a page's parent page.
        pages = pages.shuffled()
        NSLog("\(pages.count) pages used in \(#function)")

        measure {
            let list = (try? PageTree.hierarchyList(of: pages)) ?? []
            XCTAssertEqual(list.count, pages.count)
        }
    }

    // Measure performance using a page list where contains non-top-level pages and none of their parent pages are in the list.
    func testWorstPerformance() throws {
        var pages = [Page]()
        for id in 1...5000 {
            let page = PageBuilder(mainContext).build()
            page.postID = NSNumber(value: id)
            page.parentID = NSNumber(value: randomID)
            pages.append(page)
        }
        NSLog("\(pages.count) pages used in \(#function)")

        measure {
            let list = (try? PageTree.hierarchyList(of: pages)) ?? []
            XCTAssertEqual(list.count, pages.count)
        }
    }

    private func parentPage(childrenCount: Int, additionalLevels: Int = 0) -> [Page] {
        var pages = [Page]()

        let parent = PageBuilder(mainContext).build()
        parent.postID = NSNumber(value: randomID)
        parent.parentID = 0
        pages.append(parent)

        let children = (0..<childrenCount).map { _ in
            let child = PageBuilder(mainContext).build()
            child.postID = NSNumber(value: randomID)
            child.parentID = parent.postID
            return child
        }
        pages.append(contentsOf: children)

        if additionalLevels > 1 {
            let nested = parentPage(childrenCount: childrenCount, additionalLevels: additionalLevels - 1)
            nested[0].parentID = parent.postID
            pages.append(contentsOf: nested)
        }

        return pages
    }

    private func makeAssertions(pages: [Page], file: StaticString = #file, line: UInt = #line) throws {
        var start: CFAbsoluteTime

        start = CFAbsoluteTimeGetCurrent()
        let original = pages.hierarchySort()
        NSLog("hierarchySort took \(String(format: "%.3f", (CFAbsoluteTimeGetCurrent() - start) * 1000)) millisecond to process \(pages.count) pages")

        start = CFAbsoluteTimeGetCurrent()
        let new = try PageTree.hierarchyList(of: pages)
        NSLog("PageTree took \(String(format: "%.3f", (CFAbsoluteTimeGetCurrent() - start) * 1000)) millisecond to process \(pages.count) pages")

        start = CFAbsoluteTimeGetCurrent()
        _ = pages.sorted { ($0.postID?.int64Value ?? 0) < ($1.postID?.int64Value ?? 0) }
        NSLog("Array.sort took \(String(format: "%.3f", (CFAbsoluteTimeGetCurrent() - start) * 1000)) millisecond to process \(pages.count) pages")

        let originalIDs = original.map { $0.postID! }
        let newIDs = new.map { $0.postID! }
        let diff = originalIDs.difference(from: newIDs).inferringMoves()
        XCTAssertTrue(diff.count == 0, "Unexpected diff: \(diff)", file: file, line: line)
    }
}
