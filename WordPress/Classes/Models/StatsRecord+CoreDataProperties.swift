import Foundation
import CoreData

extension StatsRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StatsRecord> {
        return NSFetchRequest<StatsRecord>(entityName: "StatsRecord")
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var fetchedDate: NSDate?
    @NSManaged public var type: Int16
    @NSManaged public var period: Int16
    @NSManaged public var blog: Blog?
    @NSManaged public var values: NSOrderedSet?

}

// MARK: Generated accessors for values
extension StatsRecord {

    @objc(insertObject:inValuesAtIndex:)
    @NSManaged public func insertIntoValues(_ value: StatsRecordValue, at idx: Int)

    @objc(removeObjectFromValuesAtIndex:)
    @NSManaged public func removeFromValues(at idx: Int)

    @objc(insertValues:atIndexes:)
    @NSManaged public func insertIntoValues(_ values: [StatsRecordValue], at indexes: NSIndexSet)

    @objc(removeValuesAtIndexes:)
    @NSManaged public func removeFromValues(at indexes: NSIndexSet)

    @objc(replaceObjectInValuesAtIndex:withObject:)
    @NSManaged public func replaceValues(at idx: Int, with value: StatsRecordValue)

    @objc(replaceValuesAtIndexes:withValues:)
    @NSManaged public func replaceValues(at indexes: NSIndexSet, with values: [StatsRecordValue])

    @objc(addValuesObject:)
    @NSManaged public func addToValues(_ value: StatsRecordValue)

    @objc(removeValuesObject:)
    @NSManaged public func removeFromValues(_ value: StatsRecordValue)

    @objc(addValues:)
    @NSManaged public func addToValues(_ values: NSOrderedSet)

    @objc(removeValues:)
    @NSManaged public func removeFromValues(_ values: NSOrderedSet)

}
