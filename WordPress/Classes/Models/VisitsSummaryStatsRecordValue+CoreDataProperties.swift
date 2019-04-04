import Foundation
import CoreData


extension VisitsSummaryStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VisitsSummaryStatsRecordValue> {
        return NSFetchRequest<VisitsSummaryStatsRecordValue>(entityName: "VisitsSummaryStatsRecordValue")
    }

    @NSManaged public var viewsCount: Int64
    @NSManaged public var visitorsCount: Int64
    @NSManaged public var likesCount: Int64
    @NSManaged public var commentsCount: Int64
    @NSManaged public var periodStart: NSDate?

}
