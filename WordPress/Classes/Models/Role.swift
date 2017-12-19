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
