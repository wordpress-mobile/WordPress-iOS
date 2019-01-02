import Foundation
import CoreData

public class PlanGroup: NSManagedObject {
    @NSManaged public var order: Int16
    @NSManaged public var name: String
    @NSManaged public var slug: String
}
