import Foundation
import CoreData


extension ReferrerStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReferrerStatsRecordValue> {
        return NSFetchRequest<ReferrerStatsRecordValue>(entityName: "ReferrerStatsRecordValue")
    }

    @NSManaged public var iconURLString: String?
    @NSManaged public var label: String?
    @NSManaged public var urlString: String?
    @NSManaged public var viewsCount: Int64
    @NSManaged public var children: NSOrderedSet?
    @NSManaged public var parent: ReferrerStatsRecordValue?

}

// MARK: Generated accessors for children
extension ReferrerStatsRecordValue {

    @objc(insertObject:inChildrenAtIndex:)
    @NSManaged public func insertIntoChildren(_ value: ReferrerStatsRecordValue, at idx: Int)

    @objc(removeObjectFromChildrenAtIndex:)
    @NSManaged public func removeFromChildren(at idx: Int)

    @objc(insertChildren:atIndexes:)
    @NSManaged public func insertIntoChildren(_ values: [ReferrerStatsRecordValue], at indexes: NSIndexSet)

    @objc(removeChildrenAtIndexes:)
    @NSManaged public func removeFromChildren(at indexes: NSIndexSet)

    @objc(replaceObjectInChildrenAtIndex:withObject:)
    @NSManaged public func replaceChildren(at idx: Int, with value: ReferrerStatsRecordValue)

    @objc(replaceChildrenAtIndexes:withChildren:)
    @NSManaged public func replaceChildren(at indexes: NSIndexSet, with values: [ReferrerStatsRecordValue])

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: ReferrerStatsRecordValue)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: ReferrerStatsRecordValue)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSOrderedSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSOrderedSet)

}
