import Foundation
import CoreData


extension FollowersStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FollowersStatsRecordValue> {
        return NSFetchRequest<FollowersStatsRecordValue>(entityName: "FollowersStatsRecordValue")
    }

    @NSManaged public var name: String?
    @NSManaged public var subscribedDate: NSDate?
    @NSManaged public var avatarURLString: String?
    @NSManaged public var type: Int16

}
