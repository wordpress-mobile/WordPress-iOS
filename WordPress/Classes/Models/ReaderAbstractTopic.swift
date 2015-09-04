import Foundation
import CoreData

@objc public class ReaderAbstractTopic : NSManagedObject
{
    // Relations
    @NSManaged var account: WPAccount
    @NSManaged var posts: [ReaderPost]

    // Properties
    @NSManaged var following: Bool
    @NSManaged var lastSynced: NSDate
    @NSManaged var path: String
    @NSManaged var title: String
}
