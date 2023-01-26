import Foundation
import CoreData

public class Role: NSManagedObject {
    @NSManaged public var name: String!
    @NSManaged public var slug: String!
    @NSManaged public var blog: Blog!
    @NSManaged public var order: NSNumber!
}

extension Role {
    func toUnmanaged() -> RemoteRole {
        return RemoteRole(slug: slug, name: name)
    }

    /// Returns a role from Core Data with the given slug.
    static func lookup(withBlogID blogID: NSManagedObjectID, slug: String, in context: NSManagedObjectContext) throws -> Role? {
        guard let blog = try context.existingObject(with: blogID) as? Blog else {
            return nil
        }
        let predicate = NSPredicate(format: "slug = %@ AND blog = %@", slug, blog)
        return context.firstObject(ofType: Role.self, matching: predicate)
    }
}

extension Role {
    @objc var color: UIColor {
        switch slug {
        case .some("super-admin"):
            return WPStyleGuide.People.superAdminColor
        case .some("administrator"):
            return WPStyleGuide.People.adminColor
        case .some("editor"):
            return WPStyleGuide.People.editorColor
        default:
            return WPStyleGuide.People.otherRoleColor
        }
    }
}
