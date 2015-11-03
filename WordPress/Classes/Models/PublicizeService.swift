import Foundation
import CoreData

@objc public class PublicizeService : NSManagedObject
{
    @NSManaged public var connectURL: String
    @NSManaged public var detail: String
    @NSManaged public var icon: String
    @NSManaged public var label: String
    @NSManaged public var noticon: String
    @NSManaged public var order: NSNumber
    @NSManaged public var service: String
}
