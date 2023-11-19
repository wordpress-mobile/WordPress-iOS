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
        makeAssertions(pages: pages)
    }

    func testOneNestedList() throws {
        let pages = parentPage(childrenCount: 1, additionalLevels: 5)
        makeAssertions(pages: pages)
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

        makeAssertions(pages: pages)
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

        makeAssertions(pages: pages)
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
            let pageTree = PageTree()
            pageTree.add(pages)
            let list = pageTree.hierarchyList()
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
            let pageTree = PageTree()
            pageTree.add(pages)
            let list = pageTree.hierarchyList()
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

        makeAssertions(pages: pages)
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

    private func makeAssertions(pages: [Page], file: StaticString = #file, line: UInt = #line) {
        var start: CFAbsoluteTime

        start = CFAbsoluteTimeGetCurrent()
        let original = pages.hierarchySort()
        NSLog("hierarchySort took \(String(format: "%.3f", (CFAbsoluteTimeGetCurrent() - start) * 1000)) millisecond to process \(pages.count) pages")

        start = CFAbsoluteTimeGetCurrent()
        let pageTree = PageTree()
        pageTree.add(pages)
        let new = pageTree.hierarchyList()
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

final class PageTree {

    // A node in a tree, which of course is also a tree itself.
    private final class TreeNode {
        var page: Page
        var children = [TreeNode]()
        var parentNode: TreeNode?

        init(page: Page, children: [TreeNode] = [], parentNode: TreeNode? = nil) {
            self.page = page
            self.children = children
            self.parentNode = parentNode
        }

        // The `PageTree` type is used to loaded
        // Some page There are pages  They are pages that doesn't belong to the root level, but their parent pages haven't been loaded yet.
        var isOrphan: Bool {
            (page.parentID?.int64Value ?? 0) > 0 && parentNode == nil
        }

        func dfsList() -> [Page] {
            var pages = [Page]()
            _ = depthFirstSearch { level, node in
                node.page.hierarchyIndex = level
                pages.append(node.page)
                return false
            }
            return pages
        }

        @discardableResult
        func depthFirstSearch(using closure: (Int, TreeNode) -> Bool) -> Bool {
            depthFirstSearch(level: 0, using: closure)
        }

        func depthFirstSearch(level: Int, using closure: (Int, TreeNode) -> Bool) -> Bool {
            let shouldStop = closure(level, self)
            if shouldStop {
                return true
            }

            for child in children {
                let shouldStop = child.depthFirstSearch(level: level + 1, using: closure)
                if shouldStop {
                    return true
                }
            }

            return false
        }

        func breadthFirstSearch(using closure: (TreeNode) -> Bool) {
            var queue = [TreeNode]()
            queue.append(self)
            while let current = queue.popLast() {
                let shouldStop = closure(current)
                if shouldStop {
                    break
                }

                queue.append(contentsOf: current.children)
            }
        }

        func add(_ newNode: TreeNode) -> Bool {
            assert(newNode.parentNode == nil)

            guard let parentID = newNode.page.parentID?.int64Value, parentID != 0 else {
                return false
            }

            depthFirstSearch { _, node in
                if node.page.postID?.int64Value == parentID {
                    node.children.append(newNode)
                    newNode.parentNode = node
                    return true
                }
                return false
            }

            return newNode.parentNode != nil
        }
    }

    // The top level (or root level) pages, or nodes.
    // They can be two types node:
    // - child nodes. They are top level pages.
    // - orphan nodes. They are pages that doesn't belong to the root level, but their parent pages haven't been loaded yet.
    private var nodes = [TreeNode]()
    private var orphanNodes = IndexSet()

    func add(_ newPages: [Page]) {
        let newNodes = newPages.map { TreeNode(page: $0) }
        relocateOrphans(to: newNodes)

        let batch = 100
        for index in stride(from: 0, to: newPages.count, by: batch) {
            let tree = PageTree()
            tree.add(Array(newNodes[index..<min(index + batch, newPages.count)]))
            self.add(tree.nodes)
        }
    }

    private func relocateOrphans(to newNodes: [TreeNode]) {
        // If the orphan nodes can find their parents in `newNode`, move them under `newNode`.
        let movedOrphanIndexes = orphanNodes.filter { index in
            newNodes.contains { $0.add(nodes[index]) }
        }

        if !movedOrphanIndexes.isEmpty {
            nodes.remove(atOffsets: IndexSet(movedOrphanIndexes))
            orphanNodes = nodes.enumerated().reduce(into: IndexSet()) { indexes, node in
                if node.element.isOrphan {
                    indexes.insert(node.offset)
                }
            }
        }
    }

    private func add(_ newNodes: [TreeNode]) {
        newNodes.forEach { newNode in
            // If the new node is at the root level, then simply add it as a child
            if (newNode.page.parentID?.int64Value ?? 0) == 0 {
                nodes.append(newNode)
                return
            }

            // The new node is not at the root level, find its parent in the root level nodes.
            for child in nodes {
                if child.add(newNode) {
                    break
                }
            }

            // Still not find their parent, add it to the root level nodes.
            if newNode.parentNode == nil {
                nodes.append(newNode)
                orphanNodes.insert(nodes.count - 1)
            }
        }
    }

    func hierarchyList() -> [Page] {
        nodes.reduce(into: []) {
            $0.append(contentsOf: $1.dfsList())
        }
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
