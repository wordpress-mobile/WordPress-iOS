import Foundation
import CoreData


extension LastPostStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LastPostStatsRecordValue> {
        return NSFetchRequest<LastPostStatsRecordValue>(entityName: "LastPostStatsRecordValue")
    }

    @NSManaged public var commentsCount: Int64
    @NSManaged public var likesCount: Int64
    @NSManaged public var publishedDate: NSDate?
    @NSManaged public var title: String?
    @NSManaged public var urlString: String?
    @NSManaged public var viewsCount: Int64
    @NSManaged public var postID: Int64

}
