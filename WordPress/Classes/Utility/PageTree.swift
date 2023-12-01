final class PageTree {

    // A node in a tree, which of course is also a tree itself.
    private class TreeNode {
        struct PageData {
            var postID: NSNumber?
            var parentID: NSNumber?
        }
        let pageID: TaggedManagedObjectID<Page>
        let pageData: PageData
        var children = [TreeNode]()
        var parentNode: TreeNode?

        init(page: Page, children: [TreeNode] = [], parentNode: TreeNode? = nil) {
            self.pageID = TaggedManagedObjectID(page)
            self.pageData = PageData(postID: page.postID, parentID: page.parentID)
            self.children = children
            self.parentNode = parentNode
        }

        // The `PageTree` type is used to loaded
        // Some page There are pages  They are pages that doesn't belong to the root level, but their parent pages haven't been loaded yet.
        var isOrphan: Bool {
            (pageData.parentID?.int64Value ?? 0) > 0 && parentNode == nil
        }

        func dfsList(in context: NSManagedObjectContext) throws -> [Page] {
            var pages = [Page]()
            _ = try depthFirstSearch { level, node in
                let page = try context.existingObject(with: node.pageID)
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
        func depthFirstSearch(using closure: (Int, TreeNode) throws -> Bool) rethrows -> Bool {
            try depthFirstSearch(level: 0, using: closure)
        }

        private func depthFirstSearch(level: Int, using closure: (Int, TreeNode) throws -> Bool) rethrows -> Bool {
            let shouldStop = try closure(level, self)
            if shouldStop {
                return true
            }

            for child in children {
                let shouldStop = try child.depthFirstSearch(level: level + 1, using: closure)
                if shouldStop {
                    return true
                }
            }

            return false
        }

        /// Perform breadth-first search starting with the current (`self`) node.
        ///
        /// - Parameter closure: A closure that takes a node as argument and returns a boolean value indicate whether
        ///     the search should be stopped.
        /// - Returns: `true` if search has been stopped by the closure.
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

        func add(_ newNodes: [TreeNode], parentID: NSNumber) -> Bool {
            assert(parentID != 0)

            return depthFirstSearch { _, node in
                if node.pageData.postID == parentID {
                    node.children.append(contentsOf: newNodes)
                    newNodes.forEach { $0.parentNode = node }
                    return true
                }
                return false
            }
        }
    }

    // The top level (or root level) pages, or nodes.
    // They can be two types node:
    // - child nodes. They are top level pages.
    // - orphan nodes. They are pages that doesn't belong to the root level, but their parent pages haven't been loaded yet.
    private var nodes = [TreeNode]()

    // `orphanNodes` contains indexes of orphan nodes in the `nodes` array (the value part in the dictionary), which are
    // grouped using their parent id (the key part in the dictionary).
    // IMPORTANT: Make sure `orphanNodes` is up-to-date after the `nodes` array is modified.
    private var orphanNodes = [NSNumber: [Int]]()

    /// Add *new pages* to the page tree.
    ///
    /// This function assumes none of array elements already exists in the current page tree.
    func add(_ newPages: [Page]) {
        let newNodes = newPages.map { TreeNode(page: $0) }
        relocateOrphans(to: newNodes)

        // First try to constrcuture a smaller subtree from the given pages, then move the new subtree to the existing
        // page tree (`self`).
        // The number of pages in a subtree can be changed if we want to futher tweak the performance.
        let batch = 100
        for index in stride(from: 0, to: newNodes.count, by: batch) {
            let tree = PageTree()
            tree.add(Array(newNodes[index..<min(index + batch, newNodes.count)]))
            merge(subtree: tree)
        }
    }

    /// Find the existing orphan nodes' parents in the given new nodes list argument and move them under their parent
    /// node if found.
    private func relocateOrphans(to newNodes: [TreeNode]) {
        let relocated = orphanNodes.reduce(into: IndexSet()) { result, element in
            let parentID = element.key
            let indexes = element.value

            let toBeRelocated = indexes.map { nodes[$0] }
            let moved = newNodes.contains {
                $0.add(toBeRelocated, parentID: parentID)
            }
            if moved {
                result.formUnion(IndexSet(indexes))
            }
        }

        if !relocated.isEmpty {
            nodes.remove(atOffsets: relocated)
            orphanNodes = nodes.enumerated().reduce(into: [:]) { indexes, node in
                if node.element.isOrphan {
                    let parentID = node.element.pageData.parentID ?? 0
                    indexes[parentID, default: []].append(node.offset)
                }
            }
        }
    }

    private func add(_ newNodes: [TreeNode]) {
        newNodes.forEach { newNode in
            let parentID = newNode.pageData.parentID ?? 0

            // If the new node is at the root level, then simply add it as a child.
            if parentID == 0 {
                nodes.append(newNode)
                return
            }

            // The new node is not at the root level, find its parent in the root level nodes.
            for child in nodes {
                if child.add([newNode], parentID: parentID) {
                    break
                }
            }

            // Still not find their parent, add it to the root level nodes.
            if newNode.parentNode == nil {
                nodes.append(newNode)
                orphanNodes[parentID, default: []].append(nodes.count - 1)
            }
        }
    }

    /// Move all the nodes in the given argument to the current page tree.
    private func merge(subtree: PageTree) {
        var parentIDs = subtree.nodes.reduce(into: Set()) { $0.insert($1.pageData.parentID ?? 0) }
        // No need to look for root level
        parentIDs.remove(0)
        // Look up parent nodes upfront, to avoid repeated iteration for each node in `subtree`.
        let parentNodes = findNodes(postIDs: parentIDs)

        subtree.nodes.forEach { newNode in
            let parentID = newNode.pageData.parentID ?? 0

            // If the new node is at the root level, then simply add it as a child
            if parentID == 0 {
                nodes.append(newNode)
                return
            }

            // The new node is not at the root level, find its parent in the root level nodes.
            if let parentNode = parentNodes[parentID] {
                parentNode.children.append(newNode)
                newNode.parentNode = parentNode
            } else {
                // No parent found, add it to the root level nodes.
                nodes.append(newNode)
                orphanNodes[parentID, default: []].append(nodes.count - 1)
            }
        }
    }

    /// Find the node for the given page ids
    private func findNodes(postIDs originalIDs: Set<NSNumber>) -> [NSNumber: TreeNode] {
        guard !originalIDs.isEmpty else {
            return [:]
        }

        var ids = originalIDs
        var result = [NSNumber: TreeNode]()

        // The new node is not at the root level, find its parent in the root level nodes.
        for child in nodes {
            if ids.isEmpty {
                break
            }

            // Using BFS under the assumption that page tree in most sites is a shallow tree, where most pages are in top layers.
            child.breadthFirstSearch { node in
                let postID = node.pageData.postID ?? 0
                let foundIndex = ids.firstIndex(of: postID)
                if let foundIndex {
                    ids.remove(at: foundIndex)
                    result[postID] = node
                }
                return ids.isEmpty
            }
        }

        return result
    }

    func hierarchyList(in context: NSManagedObjectContext) throws -> [Page] {
        try nodes.reduce(into: []) {
            try $0.append(contentsOf: $1.dfsList(in: context))
        }
    }

    static func hierarchyList(of pages: [Page]) throws -> [Page] {
        guard let context = pages.first?.managedObjectContext else {
            return []
        }

        let tree = PageTree()
        tree.add(pages)
        return try tree.hierarchyList(in: context)
    }
}
