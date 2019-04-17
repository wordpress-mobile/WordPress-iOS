import Foundation
import CoreData


extension FollowersCountStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FollowersCountStatsRecordValue> {
        return NSFetchRequest<FollowersCountStatsRecordValue>(entityName: "FollowersCountStatsRecordValue")
    }

    @NSManaged public var type: Int16
    @NSManaged public var count: Int64

}
