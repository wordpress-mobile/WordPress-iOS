import Foundation
import CoreData


extension TagsCategoriesStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagsCategoriesStatsRecordValue> {
        return NSFetchRequest<TagsCategoriesStatsRecordValue>(entityName: "TagsCategoriesStatsRecordValue")
    }

    @NSManaged public var type: Int16
    @NSManaged public var name: String?
    @NSManaged public var urlString: String?
    @NSManaged public var viewsCount: Int64
    @NSManaged public var children: NSOrderedSet?

}

// MARK: Generated accessors for children
extension TagsCategoriesStatsRecordValue {

    @objc(insertObject:inChildrenAtIndex:)
    @NSManaged public func insertIntoChildren(_ value: TagsCategoriesStatsRecordValue, at idx: Int)

    @objc(removeObjectFromChildrenAtIndex:)
    @NSManaged public func removeFromChildren(at idx: Int)

    @objc(insertChildren:atIndexes:)
    @NSManaged public func insertIntoChildren(_ values: [TagsCategoriesStatsRecordValue], at indexes: NSIndexSet)

    @objc(removeChildrenAtIndexes:)
    @NSManaged public func removeFromChildren(at indexes: NSIndexSet)

    @objc(replaceObjectInChildrenAtIndex:withObject:)
    @NSManaged public func replaceChildren(at idx: Int, with value: TagsCategoriesStatsRecordValue)

    @objc(replaceChildrenAtIndexes:withChildren:)
    @NSManaged public func replaceChildren(at indexes: NSIndexSet, with values: [TagsCategoriesStatsRecordValue])

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: TagsCategoriesStatsRecordValue)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: TagsCategoriesStatsRecordValue)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSOrderedSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSOrderedSet)

}
