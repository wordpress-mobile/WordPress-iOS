import Foundation
import CoreData


extension AllTimeStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AllTimeStatsRecordValue> {
        return NSFetchRequest<AllTimeStatsRecordValue>(entityName: "AllTimeStatsRecordValue")
    }

    @NSManaged public var postsCount: Int64
    @NSManaged public var viewsCount: NSNumber?
    @NSManaged public var visitorsCount: NSNumber?
    @NSManaged public var bestViewsPerDayCount: NSNumber?
    @NSManaged public var bestViewsDay: NSDate?

}
