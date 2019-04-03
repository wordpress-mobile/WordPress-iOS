import Foundation
import CoreData


extension ClicksStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClicksStatsRecordValue> {
        return NSFetchRequest<ClicksStatsRecordValue>(entityName: "ClicksStatsRecordValue")
    }

    @NSManaged public var clicksCount: Int64
    @NSManaged public var label: String?
    @NSManaged public var urlString: String?
    @NSManaged public var iconUrlString: String?
    @NSManaged public var children: NSOrderedSet?
    @NSManaged public var parent: ClicksStatsRecordValue?

}

// MARK: Generated accessors for children
extension ClicksStatsRecordValue {

    @objc(insertObject:inChildrenAtIndex:)
    @NSManaged public func insertIntoChildren(_ value: ClicksStatsRecordValue, at idx: Int)

    @objc(removeObjectFromChildrenAtIndex:)
    @NSManaged public func removeFromChildren(at idx: Int)

    @objc(insertChildren:atIndexes:)
    @NSManaged public func insertIntoChildren(_ values: [ClicksStatsRecordValue], at indexes: NSIndexSet)

    @objc(removeChildrenAtIndexes:)
    @NSManaged public func removeFromChildren(at indexes: NSIndexSet)

    @objc(replaceObjectInChildrenAtIndex:withObject:)
    @NSManaged public func replaceChildren(at idx: Int, with value: ClicksStatsRecordValue)

    @objc(replaceChildrenAtIndexes:withChildren:)
    @NSManaged public func replaceChildren(at indexes: NSIndexSet, with values: [ClicksStatsRecordValue])

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: ClicksStatsRecordValue)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: ClicksStatsRecordValue)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSOrderedSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSOrderedSet)

}
