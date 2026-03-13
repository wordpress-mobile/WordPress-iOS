import Foundation
import CoreData

public extension PostTag {
    @NSManaged var tagID: NSNumber?
    @NSManaged var name: String
    @NSManaged var slug: String?
    @NSManaged var tagDescription: String?
    @NSManaged var postCount: NSNumber?

    @NSManaged var blog: Blog?
}
