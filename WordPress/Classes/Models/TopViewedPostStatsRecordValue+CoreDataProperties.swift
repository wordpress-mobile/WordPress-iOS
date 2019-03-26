import Foundation
import CoreData


extension TopViewedPostStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopViewedPostStatsRecordValue> {
        return NSFetchRequest<TopViewedPostStatsRecordValue>(entityName: "TopViewedPostStatsRecordValue")
    }

    @NSManaged public var postID: Int64
    @NSManaged public var viewsCount: Int64
    @NSManaged public var title: String?
    @NSManaged public var postURLString: String?
    @NSManaged public var author: TopViewedAuthorStatsRecordValue?
    @NSManaged public var type: Int16

}
