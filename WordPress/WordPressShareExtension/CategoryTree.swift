import WordPressKit.RemotePostCategory

public class CategoryTree {
    var tree: CategoryTreeNode<RemotePostCategory>

    public init(categories: [RemotePostCategory]) {
        let rootCategory = RemotePostCategory()
        rootCategory.categoryID = -1
        self.tree = CategoryTreeNode<RemotePostCategory>(value: rootCategory)

        let rootCategories = categories.filter { postCategory -> Bool in
            guard let parentID = postCategory.parentID, parentID.intValue == 0 else {
                return false
            }
            return true
        }
        rootCategories.forEach { topCategory in
            tree.addChild(CategoryTreeNode<RemotePostCategory>(value: topCategory))
        }

        let childCategories = categories.filter { postCategory -> Bool in
            guard let parentID = postCategory.parentID, parentID.intValue == 0 else {
                return true
            }
            return false
        }
        childCategories.forEach { childCategory in
            guard childCategory.parentID != nil else {
                return
            }
            if let rootCategory = rootCategories.filter({ $0.categoryID == childCategory.parentID }).first {
                let treeNode = tree.search(rootCategory)
                treeNode?.addChild(CategoryTreeNode<RemotePostCategory>(value: childCategory))
            }
        }
    }
}

public class CategoryTreeNode<T> {
    public var value: T

    public weak var parent: CategoryTreeNode?
    public var children = [CategoryTreeNode<T>]()

    public init(value: T) {
        self.value = value
    }

    public func addChild(_ node: CategoryTreeNode<T>) {
        children.append(node)
        node.parent = self
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

extension CategoryTreeNode where T: Equatable {
    public func search(_ value: T) -> CategoryTreeNode? {
        if value == self.value {
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
