import Foundation
import CoreData


extension TodayStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TodayStatsRecordValue> {
        return NSFetchRequest<TodayStatsRecordValue>(entityName: "TodayStatsRecordValue")
    }

    @NSManaged public var viewsCount: Int64
    @NSManaged public var likesCount: Int64
    @NSManaged public var commentsCount: Int64
    @NSManaged public var visitorsCount: Int64

}
