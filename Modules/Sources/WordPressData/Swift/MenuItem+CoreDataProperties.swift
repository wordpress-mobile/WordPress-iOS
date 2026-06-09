import Foundation
import CoreData

public extension MenuItem {
    @NSManaged var contentID: NSNumber?
    @NSManaged var details: String?
    @NSManaged var itemID: NSNumber?
    @NSManaged var linkTarget: String?
    @NSManaged var linkTitle: String?
    @NSManaged var name: String?
    @NSManaged var type: String?
    @NSManaged var typeFamily: String?
    @NSManaged var typeLabel: String?
    @NSManaged var urlStr: String?
    @NSManaged var classes: [String]?
    @NSManaged var menu: Menu?
    @NSManaged var children: Set<MenuItem>?
    @NSManaged var parent: MenuItem?

    @nonobjc class func fetchRequest() -> NSFetchRequest<MenuItem> {
        return NSFetchRequest<MenuItem>(entityName: "MenuItem")
    }
}

// MARK: - Relationship Accessors - Children (Set)

extension MenuItem {
    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: MenuItem)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: MenuItem)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: Set<MenuItem>)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: Set<MenuItem>)
}
