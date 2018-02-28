import WordPressKit.RemotePostCategory

public class CategoryTree {
    public var tree: CategoryTreeNode

    init(categories: [RemotePostCategory]) {
        let rootCategory = RemotePostCategory()
        rootCategory.categoryID = NSNumber(value: 0)
        rootCategory.name = "root"
        rootCategory.parentID = nil
        self.tree = CategoryTreeNode(value: rootCategory)
        let sortedCategories = categories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending }
        self.tree.addChildren(sortedCategories)
    }
}

public class CategoryTreeNode {
    public var value: RemotePostCategory
    public weak var parent: CategoryTreeNode?
    public var children = [CategoryTreeNode]()
    public var depth: Int = 0

    init(value: RemotePostCategory) {
        self.value = value
    }

    func addChild(_ node: CategoryTreeNode) {
        node.parent = self
        node.depth = self.depth + 1
        children.append(node)
    }

    func addChildren(_ values: [RemotePostCategory]) {
        guard !values.isEmpty else {
            return
        }
        values.forEach { category in
            if category.safeParentValue.isEqual(to: self.value.categoryID) {
                let child = CategoryTreeNode(value: category)
                self.addChild(child)
                child.addChildren(values)
            }
        }
    }
}

extension CategoryTreeNode: CustomStringConvertible {
    public var description: String {
        var s = "\(value)"
        if !children.isEmpty {
            s += " {" + children.map { $0.description }.joined(separator: ", ") + "}"
        }
        return s
    }
}

extension CategoryTreeNode: Equatable {
    public static func ==(lhs: CategoryTreeNode, rhs: CategoryTreeNode) -> Bool {
        if lhs.value.categoryID.isEqual(to: rhs.value.categoryID) {
            return true
        } else {
            return false
        }
    }
}

extension CategoryTreeNode {
    public func search(_ value: CategoryTreeNode) -> CategoryTreeNode? {
        if value == self {
            return self
        }
        for child in children {
            if let found = child.search(value) {
                return found
            }
        }
        return nil
    }

    func search(_ value: RemotePostCategory) -> CategoryTreeNode? {
        if value.categoryID.isEqual(to: self.value.categoryID) {
            return self
        }
        for child in children {
            if let found = child.search(value) {
                return found
            }
        }
        return nil
    }

    func allDescendants() -> [CategoryTreeNode]? {
        guard !children.isEmpty else {
            return nil
        }
        var descendants: [CategoryTreeNode] = []
        descendants += children.flatMap({ $0 })
        for child in children {
            if let found = child.allDescendants() {
                descendants += found.flatMap({ $0 })
            }
        }
        return descendants
    }
}

extension RemotePostCategory {
    var safeParentValue: NSNumber {
        guard let parentID = parentID else {
            return NSNumber(value: 0)
        }
        return parentID
    }
}
