import Foundation
import CoreData


extension OtherAndTotalViewsCountStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OtherAndTotalViewsCountStatsRecordValue> {
        return NSFetchRequest<OtherAndTotalViewsCountStatsRecordValue>(entityName: "OtherAndTotalViewsCount")
    }

    @NSManaged public var totalCount: Int64
    @NSManaged public var otherCount: Int64

}
