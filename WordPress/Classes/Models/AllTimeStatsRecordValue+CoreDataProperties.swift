import Foundation
import CoreData


extension AllTimeStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AllTimeStatsRecordValue> {
        return NSFetchRequest<AllTimeStatsRecordValue>(entityName: "AllTimeStatsRecordValue")
    }

    @NSManaged public var postsCount: Int64
    @NSManaged public var viewsCount: Int64
    @NSManaged public var visitorsCount: Int64
    @NSManaged public var bestViewsPerDayCount: Int64
    @NSManaged public var bestViewsDay: NSDate?

}
