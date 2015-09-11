import Foundation
import CoreData

@objc public class ReaderAbstractTopic : NSManagedObject
{
    // Relations
    @NSManaged public var posts: [ReaderPost]

    // Properties
    @NSManaged public var following: Bool
    @NSManaged public var lastSynced: NSDate
    @NSManaged public var path: String
    @NSManaged public var showInMenu: Bool
    @NSManaged public var title: String
    @NSManaged public var type: String

    public class var TopicType: String {
        assert(false, "Subclasses must override")
        return "abstract"
    }
}
