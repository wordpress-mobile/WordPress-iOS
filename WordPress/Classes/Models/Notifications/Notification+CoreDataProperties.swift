import Foundation
import CoreData


// MARK: - Notification Core Data Properties
//
extension Notification {

    @NSManaged var icon: String?
    @NSManaged var noticon: String?

    @NSManaged var read: NSNumber?
    @NSManaged var timestamp: String?
    @NSManaged var type: String?
    @NSManaged var url: String?
    @NSManaged var title: String?

    @NSManaged var subject: [AnyObject]?
    @NSManaged var header: [AnyObject]?
    @NSManaged var body: [AnyObject]?
    @NSManaged var meta: NSDictionary?
}
