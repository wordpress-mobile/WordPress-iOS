import Foundation
import CoreData

public class PlanGroup: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlanGroup> {
        return NSFetchRequest<PlanGroup>(entityName: "PlanGroup")
    }

    @NSManaged public var order: Int16
    @NSManaged public var name: String
    @NSManaged public var slug: String

}
