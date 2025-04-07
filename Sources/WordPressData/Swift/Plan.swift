import Foundation
import CoreData

public class Plan: NSManagedObject {
    @NSManaged public var order: Int16
    @NSManaged public var tagline: String
    @NSManaged public var shortname: String
    @NSManaged public var name: String
    @NSManaged public var products: String
    @NSManaged public var groups: String
    @NSManaged public var summary: String
    @NSManaged public var features: String
    @NSManaged public var icon: String
    @NSManaged public var supportPriority: Int16
    @NSManaged public var supportName: String
    @NSManaged public var nonLocalizedShortname: String
}
