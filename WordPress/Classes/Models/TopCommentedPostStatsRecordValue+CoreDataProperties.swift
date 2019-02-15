import Foundation
import CoreData


extension TopCommentedPostStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopCommentedPostStatsRecordValue> {
        return NSFetchRequest<TopCommentedPostStatsRecordValue>(entityName: "TopCommentedPostStatsRecordValue")
    }

    @NSManaged public var postURLString: String?
    @NSManaged public var commentCount: Int64
    @NSManaged public var postID: String?
    @NSManaged public var title: String?

}
