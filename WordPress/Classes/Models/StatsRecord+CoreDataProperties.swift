import Foundation
import CoreData


extension StatsRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StatsRecord> {
        return NSFetchRequest<StatsRecord>(entityName: "StatsRecord")
    }

    @NSManaged public var type: Int16
    @NSManaged public var date: NSDate?
    @NSManaged public var fetchedDate: NSDate?
    @NSManaged public var blog: Blog?
    @NSManaged public var values: NSOrderedSet?

}

// MARK: Generated accessors for values
extension StatsRecord {

    @objc(addValuesObject:)
    @NSManaged public func addToValues(_ value: StatsRecordValue)

    @objc(removeValuesObject:)
    @NSManaged public func removeFromValues(_ value: StatsRecordValue)

    @objc(addValues:)
    @NSManaged public func addToValues(_ values: NSSet)

    @objc(removeValues:)
    @NSManaged public func removeFromValues(_ values: NSSet)

}
