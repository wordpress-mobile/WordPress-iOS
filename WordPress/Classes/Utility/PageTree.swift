final class PageTree {

    // A node in a tree, which of course is also a tree itself.
    private class TreeNode {
        struct PageData {
            var postID: NSNumber?
            var parentID: NSNumber?
        }
        let page: Page
        var children = [TreeNode]()
        var parentNode: TreeNode?

        init(page: Page) {
            self.page = page
        }

        func dfsList() -> [Page] {
            var pages = [Page]()
            _ = depthFirstSearch { level, node in
                let page = node.page
                page.hierarchyIndex = level
                page.hasVisibleParent = node.parentNode != nil
                pages.append(page)
                return false
            }
            return pages
        }

        /// Perform depth-first search starting with the current (`self`) node.
        ///
        /// - Parameter closure: A closure that takes a node and its level in the page tree as arguments and returns
        ///     a boolean value indicate whether the search should be stopped.
        /// - Returns: `true` if search has been stopped by the closure.
        @discardableResult
        func depthFirstSearch(using closure: (Int, TreeNode) -> Bool) -> Bool {
            depthFirstSearch(level: 0, using: closure)
        }

        private func depthFirstSearch(level: Int, using closure: (Int, TreeNode) -> Bool) -> Bool {
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
    }

    static func hierarchyList(of pages: [Page]) -> [Page] {
        // An array of `TreeNode` instances that are one-to-one map of the `pages` list.
        var nodes: [TreeNode] = []
        // A map of parent page (the dictionary key) to its children (the dictionary value).
        var children: [NSNumber: [TreeNode]] = [:]
        var allPostIDs: Set<NSNumber> = []

        for page in pages {
            let node = TreeNode(page: page)
            nodes.append(node)
            allPostIDs.insert(page.postID ?? 0)
            children[page.parentID ?? 0, default: []].append(node)
        }

        // Move children nodes to through the given node and its descendants.
        func addChildren(to node: TreeNode) {
            node.children = children[node.page.postID ?? 0] ?? []
            node.children.forEach(addChildren(to:))
        }

        // The top level nodes are pages whose parent id is 0 and pages whose parent page are not in the `pages` list.
        let topLevelNodes = nodes.filter {
            let parentID = $0.page.parentID ?? 0
            return ($0.page.parentID ?? 0) == 0 || !allPostIDs.contains(parentID)
        }

        topLevelNodes.forEach(addChildren(to:))

        return topLevelNodes.reduce(into: []) {
            $0.append(contentsOf: $1.dfsList())
        }
    }
}
