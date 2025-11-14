import Foundation
import CoreData

@objc(MenuItem)
public class MenuItem: NSManagedObject {

    @objc public static let linkTargetBlank = "_blank"
    @objc public static let defaultLinkTitle = "New Item"

    @objc(labelForType:blog:)
    public static func label(for itemType: String?, blog: Blog? = nil) -> String? {
        guard let itemType else { return nil }

        switch itemType {
        case MenuItemType.page:
            return NSLocalizedString(
                "Page",
                comment: "Menu item label for linking a page."
            )
        case MenuItemType.post:
            return NSLocalizedString(
                "Post",
                comment: "Menu item label for linking a post."
            )
        case MenuItemType.custom:
            return NSLocalizedString(
                "Link",
                comment: "Menu item label for linking a custom source URL."
            )
        case MenuItemType.category:
            return NSLocalizedString(
                "Category",
                comment: "Menu item label for linking a specific category."
            )
        case MenuItemType.tag:
            return NSLocalizedString(
                "Tag",
                comment: "Menu item label for linking a specific tag."
            )
        case MenuItemType.jetpackTestimonial:
            return NSLocalizedString(
                "Testimonials",
                comment: "Menu item label for linking a testimonial post."
            )
        case MenuItemType.jetpackPortfolio:
            return NSLocalizedString(
                "Projects",
                comment: "Menu item label for linking a project page."
            )
        case MenuItemType.jetpackComic:
            return NSLocalizedString(
                "Comics",
                comment: "Menu item label for linking a comic page."
            )
        default:
            for postType in (blog?.postTypes ?? []) {
                if let postType = postType as? PostType, postType.name == itemType {
                    return postType.label
                }
            }
            return nil
        }
    }

    @objc public static func defaultItemNameLocalized() -> String {
        return NSLocalizedString(
            "New item",
            comment: "Menu item title text used as default when creating a new menu item."
        )
    }

    @objc(isDescendantOfItem:)
    public func isDescendant(of item: MenuItem) -> Bool {
        var ancestor = parent
        while let current = ancestor {
            if current == item {
                return true
            }
            ancestor = current.parent
        }
        return false
    }

    @objc(lastDescendantInOrderedItems:)
    public func lastDescendant(in orderedItems: NSOrderedSet) -> MenuItem? {
        let parentIndex = orderedItems.index(of: self)
        guard parentIndex != NSNotFound else { return nil }

        var lastChildItem: MenuItem? = nil
        for i in (parentIndex + 1)..<orderedItems.count {
            if let child = orderedItems.object(at: i) as? MenuItem {
                if child.parent == self {
                    lastChildItem = child
                }
                if let lastChildItem, !lastChildItem.isDescendant(of: self) {
                    break
                }
            }
        }
        return lastChildItem
    }

    @objc
    public var nameIsEmptyOrDefault: Bool {
        guard let name else { return true }
        return name.isEmpty || name == MenuItem.defaultItemNameLocalized()
    }

    @objc(precedingSiblingInOrderedItems:)
    public func precedingSibling(in orderedItems: NSOrderedSet) -> MenuItem? {
        let selfIndex = orderedItems.index(of: self)
        guard selfIndex != NSNotFound else { return nil }

        for idx in stride(from: selfIndex - 1, through: 0, by: -1) {
            if let previousItem = orderedItems.object(at: idx) as? MenuItem {
                if previousItem.parent == parent {
                    return previousItem
                }
            }
        }
        return nil
    }
}

// MARK: - Constants

@objcMembers public class MenuItemType: NSObject {
    public static let page = "page"
    public static let custom = "custom"
    public static let category = "category"
    public static let tag = "post_tag"
    public static let post = "post"
    public static let jetpackTestimonial = "jetpack-testimonial"
    public static let jetpackPortfolio = "jetpack-portfolio"
    public static let jetpackComic = "jetpack-comic"
}
