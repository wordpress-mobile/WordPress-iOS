import Foundation
import CoreData

public class PublicizeService : NSManagedObject
{
    @NSManaged public var connectURL: String
    @NSManaged public var detail: String
    @NSManaged public var icon: String
    @NSManaged public var jetpackSupport: Bool
    @NSManaged public var jetpackModuleRequired: String
    @NSManaged public var label: String
    @NSManaged public var multipleExternalUserIDSupport: Bool
    @NSManaged public var order: NSNumber
    @NSManaged public var serviceID: String
    @NSManaged public var type: String
}
