import Foundation
import WordPressKit

/// Service providing access to user roles
///
struct RoleService {
    let blog: Blog

    fileprivate let context: NSManagedObjectContext
    fileprivate let remote: PeopleServiceRemote
    fileprivate let siteID: Int

    init?(blog: Blog, context: NSManagedObjectContext) {
        guard let api = blog.wordPressComRestApi(), let dotComID = blog.dotComID as? Int else {
            return nil
        }

        self.remote = PeopleServiceRemote(wordPressComRestApi: api)
        self.siteID = dotComID
        self.blog = blog
        self.context = context
    }

    /// Returns a role from Core Data with the given slug.
    ///
    func getRole(slug: String) -> Role? {
        let predicate = NSPredicate(format: "slug = %@ AND blog = %@", slug, blog)
        return context.firstObject(ofType: Role.self, matching: predicate)
    }

    /// Forces a refresh of roles from the api and stores them in Core Data.
    ///
    func fetchRoles(success: @escaping ([Role]) -> Void, failure: @escaping (Error) -> Void) {
        remote.getUserRoles(siteID, success: { (remoteRoles) in
            let roles = self.mergeRoles(remoteRoles)
            success(roles)
        }, failure: failure)
    }
}

private extension RoleService {
    func mergeRoles(_ remoteRoles: [RemoteRole]) -> [Role] {
        let existingRoles = blog.roles ?? []
        var rolesToKeep = [Role]()
        for (order, remoteRole) in remoteRoles.enumerated() {
            let role: Role
            if let existingRole = existingRoles.first(where: { $0.slug == remoteRole.slug }) {
                role = existingRole
            } else {
                role = context.insertNewObject(ofType: Role.self)
            }
            role.blog = blog
            role.slug = remoteRole.slug
            role.name = remoteRole.name
            role.order = order as NSNumber
            rolesToKeep.append(role)
        }
        let rolesToDelete = existingRoles.subtracting(rolesToKeep)
        rolesToDelete.forEach(context.delete(_:))
        ContextManager.sharedInstance().save(context)
        return rolesToKeep
    }
}
