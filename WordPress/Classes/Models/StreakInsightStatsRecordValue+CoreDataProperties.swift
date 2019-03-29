import Foundation
import CoreData


extension StreakInsightStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StreakInsightStatsRecordValue> {
        return NSFetchRequest<StreakInsightStatsRecordValue>(entityName: "StreakInsightStatsRecordValue")
    }

    @NSManaged public var currentStreakEnd: NSDate?
    @NSManaged public var currentStreakLength: Int64
    @NSManaged public var currentStreakStart: NSDate?
    @NSManaged public var longestStreakEnd: NSDate?
    @NSManaged public var longestStreakLength: Int64
    @NSManaged public var longestStreakStart: NSDate?
    @NSManaged public var streakData: NSOrderedSet?

}

// MARK: Generated accessors for streakData
extension StreakInsightStatsRecordValue {

    @objc(insertObject:inStreakDataAtIndex:)
    @NSManaged public func insertIntoStreakData(_ value: StreakStatsRecordValue, at idx: Int)

    @objc(removeObjectFromStreakDataAtIndex:)
    @NSManaged public func removeFromStreakData(at idx: Int)

    @objc(insertStreakData:atIndexes:)
    @NSManaged public func insertIntoStreakData(_ values: [StreakStatsRecordValue], at indexes: NSIndexSet)

    @objc(removeStreakDataAtIndexes:)
    @NSManaged public func removeFromStreakData(at indexes: NSIndexSet)

    @objc(replaceObjectInStreakDataAtIndex:withObject:)
    @NSManaged public func replaceStreakData(at idx: Int, with value: StreakStatsRecordValue)

    @objc(replaceStreakDataAtIndexes:withStreakData:)
    @NSManaged public func replaceStreakData(at indexes: NSIndexSet, with values: [StreakStatsRecordValue])

    @objc(addStreakDataObject:)
    @NSManaged public func addToStreakData(_ value: StreakStatsRecordValue)

    @objc(removeStreakDataObject:)
    @NSManaged public func removeFromStreakData(_ value: StreakStatsRecordValue)

    @objc(addStreakData:)
    @NSManaged public func addToStreakData(_ values: NSOrderedSet)

    @objc(removeStreakData:)
    @NSManaged public func removeFromStreakData(_ values: NSOrderedSet)

}
