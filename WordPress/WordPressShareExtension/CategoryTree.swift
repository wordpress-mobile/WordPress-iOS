import WordPressKit.RemotePostCategory

public class CategoryTree {
    public var tree: CategoryTreeNode

    public var rootCategory: RemotePostCategory = {
        let root = RemotePostCategory()
        root.categoryID = TreeConstants.rootNodeID
        root.name = TreeConstants.rootNodeName
        root.parentID = nil
        return root
    }()

    init(categories: [RemotePostCategory]) {
        self.tree = CategoryTreeNode(value: self.rootCategory)
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
    var sortedTreeAsArray: [RemotePostCategory] {
        var returnValue: [RemotePostCategory] = []
        if value.categoryID != TreeConstants.rootNodeID {
            returnValue.append(value)
        }

        if !children.isEmpty {
            for child in children {
                returnValue += child.sortedTreeAsArray
            }
        }
        return returnValue
    }

    func search(_ value: CategoryTreeNode) -> CategoryTreeNode? {
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
}

// MARK: - RemotePostCategory Helper

extension RemotePostCategory {
    var safeParentValue: NSNumber {
        guard let parentID = parentID else {
            return NSNumber(value: 0)
        }
        return parentID
    }
}

// MARK: - Constants

fileprivate struct TreeConstants {
    static let rootNodeID   = NSNumber(value: 0)
    static let rootNodeName = "root"
}
