import Foundation
import CoreData

@objc public class ReaderCrossPostMeta : NSManagedObject, ManagedObject
{
    static let entityName = "ReaderCrossPostMeta"

    // Relations
    @NSManaged public var post: ReaderPost

    // Properties
    @NSManaged public var siteURL: String
    @NSManaged public var postURL: String
    @NSManaged public var commentURL: String
    @NSManaged public var siteID: NSNumber
    @NSManaged public var postID: NSNumber
}
