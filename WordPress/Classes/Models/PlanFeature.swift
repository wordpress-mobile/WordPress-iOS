import Foundation
import CoreData

public class PlanFeature: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlanFeature> {
        return NSFetchRequest<PlanFeature>(entityName: "PlanFeature")
    }

    @NSManaged public var summary: String?
    @NSManaged public var title: String?
    @NSManaged public var slug: String?

}
