import Foundation
import CoreData

@objc public class ReaderAbstractTopic : NSManagedObject
{
    // Relations
    @NSManaged var posts: [ReaderPost]

    // Properties
    @NSManaged var following: Bool
    @NSManaged var lastSynced: NSDate
    @NSManaged var path: String
    @NSManaged var showInMenu: Bool
    @NSManaged var title: String
    @NSManaged var type: String

}
