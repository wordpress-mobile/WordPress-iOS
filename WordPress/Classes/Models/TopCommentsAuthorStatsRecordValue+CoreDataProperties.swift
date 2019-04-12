import Foundation
import CoreData


extension TopCommentsAuthorStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopCommentsAuthorStatsRecordValue> {
        return NSFetchRequest<TopCommentsAuthorStatsRecordValue>(entityName: "TopCommentsAuthorStatsRecordValue")
    }

    @NSManaged public var name: String?
    @NSManaged public var commentCount: Int64
    @NSManaged public var avatarURLString: String?

}
