import Foundation
import XCTest

@testable import WordPress

class PagesListTests: CoreDataTestCase {

    let randomID = UniquePool<Int>(range: 1...999999)

    func testFlatList() throws {
        let total = 1000
        let pages = (1...total).map { id in
            let page = PageBuilder(mainContext).build()
            page.postID = NSNumber(value: id)
            return page
        }
        try makeAssertions(pages: pages)
    }

    func testOneNestedList() throws {
        let pages = parentPage(childrenCount: 1, additionalLevels: 5)
        try makeAssertions(pages: pages)
    }

    func testManyNestedLists() throws {
        let groups = [
            parentPage(childrenCount: 5),
            parentPage(childrenCount: 5),
            parentPage(childrenCount: 5),
            parentPage(childrenCount: 5),
            parentPage(childrenCount: 5)
        ]
        groups[0][1].parentID = NSNumber(value: randomID.next())
        groups[0][2].parentID = NSNumber(value: randomID.next())
        groups[0][4].parentID = NSNumber(value: randomID.next())
        let pages = groups.flatMap { $0 }

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
            newPages[0].parentID = NSNumber(value: randomID.next())
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
            newPages[0].parentID = NSNumber(value: randomID.next())
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
            page.parentID = NSNumber(value: randomID.next())
            pages.append(page)
        }
        NSLog("\(pages.count) pages used in \(#function)")

        measure {
            let list = (try? PageTree.hierarchyList(of: pages)) ?? []
            XCTAssertEqual(list.count, pages.count)
        }
    }

    func testOrphanPagesNestedLists() throws {
        var pages = [Page]()
        let orphan1 = parentPage(childrenCount: 0)
        pages.append(contentsOf: orphan1)
        pages.append(contentsOf: parentPage(childrenCount: 2))
        let orphan2 = parentPage(childrenCount: 2)
        pages.append(contentsOf: orphan2)
        pages.append(contentsOf: parentPage(childrenCount: 2))
        orphan1[0].parentID = 100000
        orphan2[0].parentID = 200000

        try makeAssertions(pages: pages)
    }

    func testHierachyListRepresentationRoundtrip() throws {
        let roundtrip: (String) throws -> Void = { string in
            let pages = try Array<Page>(hierarchyListRepresentation: string, context: self.mainContext)
            try XCTAssertEqual(PageTree.hierarchyList(of: pages).hierarchyListRepresentation(), string)
        }

        try roundtrip("""
            1
              2
            3
              4
                5
              6
            7
            """)

        try roundtrip("""
            1
              2
                3
              4
                5
              6
            7
            """)
    }

    private func parentPage(childrenCount: Int, additionalLevels: Int = 0) -> [Page] {
        var pages = [Page]()

        let parent = PageBuilder(mainContext).build()
        parent.postID = NSNumber(value: randomID.next())
        parent.parentID = 0
        pages.append(parent)

        let children = (0..<childrenCount).map { _ in
            let child = PageBuilder(mainContext).build()
            child.postID = NSNumber(value: randomID.next())
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

class UniquePool<Value: FixedWidthInteger> {
    private var taken: Set<Value> = []
    let range: ClosedRange<Value>

    init(range: ClosedRange<Value>) {
        self.range = range
    }

    func next() -> Value {
        repeat {
            precondition(taken.count < range.count, "None left")

            let value = Value.random(in: range)
            if !taken.contains(value) {
                taken.insert(value)
                return value
            }
        } while true
    }
}

private extension Array where Element == Page {

    static let indentation = 2

    /// A string representation of a pages list whose element has a valid `hierarchyIndex` value.
    ///
    /// The output looks similar to the Pages List in the app, where child page is indented based on it's hierachy level.
    ///
    /// For example, this output here represents four page instances. The digits in the string are page ids.
    /// Page 1 and 4 are top level pages. Page 1 has two child page: 2 and 3.
    /// ```
    /// 1
    ///   2
    ///   3
    /// 4
    /// ```
    ///
    /// The output can be converted back to `Page` instances using the init function below.
    func hierarchyListRepresentation() -> String {
        map { page in
            "\(String(repeating: " ", count: page.hierarchyIndex * Self.indentation))\(page.postID!)"
        }
        .joined(separator: "\n")
    }

    /// See the doc in `hierarchyListRepresentation`.
    init(hierarchyListRepresentation: String, context: NSManagedObjectContext) throws {
        var pages = [Page]()

        // The non-root-level parent pages. The first element is the parent page at level 1, the second element is the parent page at level 2, and so on.
        var parentStack = [Page]()
        for line in hierarchyListRepresentation.split(separator: "\n") {
            let firstNonWhitespaceIndex = try XCTUnwrap(line.firstIndex(where: { $0 != " " }))
            let leadingSpaces = line.distance(from: line.startIndex, to: firstNonWhitespaceIndex)
            // 'level' starts with 0 (the root).
            let level = leadingSpaces / Self.indentation

            let page = PageBuilder(context).build()
            page.postID = try NSNumber(value: XCTUnwrap(Int64(line.trimmingCharacters(in: .whitespaces))))
            page.parentID = level == 0 ? 0 : parentStack[level - 1].postID
            pages.append(page)

            parentStack.removeLast(parentStack.count - level)
            parentStack.append(page)
        }

        self = pages
    }
}
