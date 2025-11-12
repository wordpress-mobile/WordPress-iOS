import Foundation
import CoreData

public extension PostType {
    @NSManaged var apiQueryable: NSNumber?
    @NSManaged var label: String?
    @NSManaged var name: String?
    @NSManaged var blog: Blog?
}
