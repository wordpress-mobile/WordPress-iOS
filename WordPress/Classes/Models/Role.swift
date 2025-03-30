import Foundation
import CoreData

public class Role: NSManagedObject {
    @NSManaged public var name: String!
    @NSManaged public var slug: String!
    @NSManaged public var blog: Blog!
    @NSManaged public var order: NSNumber!
}

public extension Role {
    func toUnmanaged() -> RemoteRole {
        return RemoteRole(slug: slug, name: name)
    }

    static func lookup(withBlogID blogID: NSManagedObjectID, slug: String, in context: NSManagedObjectContext) throws -> Role? {
        guard let blog = try context.existingObject(with: blogID) as? Blog else {
            return nil
        }
        let predicate = NSPredicate(format: "slug = %@ AND blog = %@", slug, blog)
        return context.firstObject(ofType: Role.self, matching: predicate)
    }
}
