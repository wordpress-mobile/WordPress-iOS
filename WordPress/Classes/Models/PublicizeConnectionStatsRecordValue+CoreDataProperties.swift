import Foundation
import CoreData


extension PublicizeConnectionStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PublicizeConnectionStatsRecordValue> {
        return NSFetchRequest<PublicizeConnectionStatsRecordValue>(entityName: "PublicizeConnectionStatsRecordValue")
    }

    @NSManaged public var name: String?
    @NSManaged public var followersCount: Int64
    @NSManaged public var iconURLString: String?

}
