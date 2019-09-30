import Foundation
import CoreData

extension FileDownloadsStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileDownloadsStatsRecordValue> {
        return NSFetchRequest<FileDownloadsStatsRecordValue>(entityName: "FileDownloadsStatsRecordValue")
    }

    @NSManaged public var downloadCount: Int64
    @NSManaged public var file: String?

}
