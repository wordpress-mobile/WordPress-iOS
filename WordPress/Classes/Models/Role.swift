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

    static func lookup(withBlogID blogID: NSManagedObjectID, slug: String, in context: NSManagedObjectContext) throws -> Role? {
        guard let blog = try context.existingObject(with: blogID) as? Blog else {
            return nil
        }
        let predicate = NSPredicate(format: "slug = %@ AND blog = %@", slug, blog)
        return context.firstObject(ofType: Role.self, matching: predicate)
    }
}

extension Role {
    @objc var backgroundColor: UIColor {
        switch slug {
        case .some("super-admin"):
            return .DS.Foreground.primary
        case .some("administrator"):
            return .DS.Foreground.primary
        case .some("editor"):
            return .DS.Background.secondary
        default:
            return .DS.Background.secondary
        }
    }

    @objc var textColor: UIColor {
        switch slug {
        case .some("super-admin"):
            return .DS.Background.primary
        case .some("administrator"):
            return .DS.Background.primary
        case .some("editor"):
            return .DS.Foreground.primary
        default:
            return .DS.Foreground.primary
        }
    }
}
