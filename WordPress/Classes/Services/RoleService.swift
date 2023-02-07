import Foundation
import WordPressKit

/// Service providing access to user roles
///
struct RoleService {
    let blog: Blog

    fileprivate let coreDataStack: CoreDataStack
    fileprivate let remote: PeopleServiceRemote
    fileprivate let siteID: Int

    init?(blog: Blog, coreDataStack: CoreDataStack) {
        guard let api = blog.wordPressComRestApi(), let dotComID = blog.dotComID as? Int else {
            return nil
        }

        self.remote = PeopleServiceRemote(wordPressComRestApi: api)
        self.siteID = dotComID
        self.blog = blog
        self.coreDataStack = coreDataStack
    }

    /// Forces a refresh of roles from the api and stores them in Core Data.
    ///
    func fetchRoles(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.getUserRoles(siteID, success: { (remoteRoles) in
            self.coreDataStack.performAndSave({ context in
                self.mergeRoles(remoteRoles, in: context)
            }, completion: success, on: .main)
        }, failure: failure)
    }
}

private extension RoleService {
    func mergeRoles(_ remoteRoles: [RemoteRole], in context: NSManagedObjectContext) {
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
    }
}
