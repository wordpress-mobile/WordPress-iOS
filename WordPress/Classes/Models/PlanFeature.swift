import Foundation
import CoreData

public class PlanFeature: NSManagedObject {
    @NSManaged public var summary: String
    @NSManaged public var title: String
    @NSManaged public var slug: String
}
