import Foundation
import CoreData


extension StreakStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StreakStatsRecordValue> {
        return NSFetchRequest<StreakStatsRecordValue>(entityName: "StreakStatsRecordValue")
    }

    @NSManaged public var postCount: Int64
    @NSManaged public var date: NSDate?
    @NSManaged public var streakInsight: StreakInsightStatsRecordValue?

}
