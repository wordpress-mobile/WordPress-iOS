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

}
