import Foundation
import CoreData

public extension Menu {
    @NSManaged var details: String?
    @NSManaged var menuID: NSNumber?
    @NSManaged var name: String?
    @NSManaged var blog: Blog?
    @NSManaged var items: NSOrderedSet?
    @NSManaged var locations: Set<MenuLocation>?
}

// MARK: - Relationship Accessors - Items (NSOrderedSet)

extension Menu {
    @objc(insertObject:inItemsAtIndex:)
    @NSManaged public func insertIntoItems(_ value: MenuItem, at idx: Int)

    @objc(removeObjectFromItemsAtIndex:)
    @NSManaged public func removeFromItems(at idx: Int)

    @objc(insertItems:atIndexes:)
    @NSManaged public func insertIntoItems(_ values: [MenuItem], at indexes: NSIndexSet)

    @objc(removeItemsAtIndexes:)
    @NSManaged public func removeFromItems(at indexes: NSIndexSet)

    @objc(replaceObjectInItemsAtIndex:withObject:)
    @NSManaged public func replaceItems(at idx: Int, with value: MenuItem)

    @objc(replaceItemsAtIndexes:withItems:)
    @NSManaged public func replaceItems(at indexes: NSIndexSet, with values: [MenuItem])

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: MenuItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: MenuItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSOrderedSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSOrderedSet)
}

// MARK: - Relationship Accessors - Locations (Set)

extension Menu {
    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: MenuLocation)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: MenuLocation)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: Set<MenuLocation>)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: Set<MenuLocation>)
}
