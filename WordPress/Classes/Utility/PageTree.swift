import WordPressData

protocol HierarchicalPost: Identifiable {
    var postId: Int64 { get }
    var parentPostId: Int64 { get }
    var order: Int64 { get }
}

final class PageTree {

    struct Entry<ID: Hashable>: Equatable {
        let id: ID
        let indentationLevel: Int
        let hasVisibleParent: Bool
    }

    // A node in a tree, which of course is also a tree itself.
    private class TreeNode<ID: Hashable> {
        let id: ID
        let postId: Int64
        let parentPostId: Int64
        let order: Int64

        var children = [TreeNode]()
        var parentNode: TreeNode?

        init<P: HierarchicalPost>(post: P) where P.ID == ID {
            self.id = post.id
            self.postId = post.postId
            self.parentPostId = post.parentPostId
            self.order = post.order
        }

        func dfsList() -> [Entry<ID>] {
            var entries = [Entry<ID>]()
            depthFirstSearch(level: 0) { level, node in
                entries.append(Entry(
                    id: node.id,
                    indentationLevel: level,
                    hasVisibleParent: node.parentNode != nil
                ))
            }
            return entries
        }

        /// Perform depth-first search starting with the current (`self`) node.
        private func depthFirstSearch(level: Int, using closure: (Int, TreeNode) -> Void) {
            closure(level, self)
            let sorted = children.sorted { $0.order < $1.order }
            for child in sorted {
                child.depthFirstSearch(level: level + 1, using: closure)
            }
        }
    }

    static func buildHierarchy<P: HierarchicalPost>(from posts: [P]) -> [Entry<P.ID>] {
        // An array of `TreeNode` instances that are one-to-one map of the `posts` list.
        var nodes: [TreeNode<P.ID>] = []
        // A map of parent post (the dictionary key) to its children (the dictionary value).
        var children: [Int64: [TreeNode<P.ID>]] = [:]
        var allPostIDs: Set<Int64> = []

        for post in posts {
            let node = TreeNode(post: post)
            nodes.append(node)
            allPostIDs.insert(post.postId)
            children[post.parentPostId, default: []].append(node)
        }

        // Move children nodes to the given node and its descendants.
        func addChildren(to node: TreeNode<P.ID>) {
            node.children = children[node.postId] ?? []
            for child in node.children {
                child.parentNode = node
            }
            node.children.forEach(addChildren(to:))
        }

        // The top level nodes are posts whose parent id is 0 and posts whose parent are not in the `posts` list.
        let topLevelNodes = nodes.filter {
            $0.parentPostId == 0 || !allPostIDs.contains($0.parentPostId)
        }

        topLevelNodes.forEach(addChildren(to:))

        return topLevelNodes.reduce(into: []) {
            $0.append(contentsOf: $1.dfsList())
        }
    }

    static func hierarchyList(of pages: [Page]) -> [Page] {
        let entries = buildHierarchy(from: pages.map { HierarchicalPage(page: $0) })
        let pageMap = Dictionary(pages.map { ($0.objectID, $0) }, uniquingKeysWith: { first, _ in first })

        return entries.compactMap { entry -> Page? in
            guard let page = pageMap[entry.id] else { return nil }
            page.hierarchyIndex = entry.indentationLevel
            page.hasVisibleParent = entry.hasVisibleParent
            return page
        }
    }
}

private struct HierarchicalPage: HierarchicalPost {
    let page: Page

    var id: NSManagedObjectID {
        page.objectID
    }

    var postId: Int64 {
        page.postID?.int64Value ?? 0
    }

    var parentPostId: Int64 {
        page.parentID?.int64Value ?? 0
    }

    var order: Int64 {
        page.order
    }
}
