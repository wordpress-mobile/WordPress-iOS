import Foundation
import CoreData

@objc(ReaderCrossPostMeta)
open class ReaderCrossPostMeta: NSManagedObject {
    // Relations
    @NSManaged open var post: ReaderPost

    // Properties
    @NSManaged open var siteURL: String
    @NSManaged open var postURL: String
    @NSManaged open var commentURL: String
    @NSManaged open var siteID: NSNumber
    @NSManaged open var postID: NSNumber
}
