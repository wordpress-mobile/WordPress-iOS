import Foundation
import CoreData


extension TopViewedVideoStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopViewedVideoStatsRecordValue> {
        return NSFetchRequest<TopViewedVideoStatsRecordValue>(entityName: "TopViewedVideoStatsRecordValue")
    }

    @NSManaged public var postID: String?
    @NSManaged public var postURLString: String?
    @NSManaged public var title: String?
    @NSManaged public var playsCount: Int64

}
