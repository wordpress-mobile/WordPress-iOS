import Foundation
import CocoaLumberjack
import WordPressKit

/// Service providing access to the People Management WordPress.com API.
///
struct PeopleService {
    // MARK: - Public Properties
    ///
    let siteID: Int

    // MARK: - Private Properties
    ///
    fileprivate let context: NSManagedObjectContext
    fileprivate let remote: PeopleServiceRemote


    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - blog: Target Blog Instance
    ///     - context: CoreData context to be used.
    ///
    init?(blog: Blog, context: NSManagedObjectContext) {
        guard let api = blog.wordPressComRestApi(), let dotComID = blog.dotComID as? Int else {
            return nil
        }

        self.remote = PeopleServiceRemote(wordPressComRestApi: api)
        self.siteID = dotComID
        self.context = context
    }

    /// Loads a page of Users associated to the current blog, starting at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: Number of records to skip.
    ///     - count: Number of records to retrieve. By default set to 20.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure.
    ///
    func loadUsersPage(_ offset: Int = 0, count: Int = 20, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void), failure: ((Error) -> Void)? = nil) {
        remote.getUsers(siteID, offset: offset, count: count, success: { users, hasMore in
            self.mergePeople(users)
            success(users.count, hasMore)

        }, failure: { error in
            DDLogError(String(describing: error))
            failure?(error)
        })
    }

    /// Loads a page of Followers associated to the current blog, starting at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: Number of records to skip.
    ///     - count: Number of records to retrieve. By default set to 20.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure.
    ///
    func loadFollowersPage(_ offset: Int = 0, count: Int = 20, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void), failure: ((Error) -> Void)? = nil) {
        remote.getFollowers(siteID, offset: offset, count: count, success: { followers, hasMore in
            self.mergePeople(followers)
            success(followers.count, hasMore)
        }, failure: { error in
            DDLogError(String(describing: error))
            failure?(error)
        })
    }

    /// Loads a page of Viewers associated to the current blog, starting at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: Number of records to skip.
    ///     - count: Number of records to retrieve. By default set to 20.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure.
    ///
    func loadViewersPage(_ offset: Int = 0, count: Int = 20, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void), failure: ((Error) -> Void)? = nil) {
        remote.getViewers(siteID, offset: offset, count: count, success: { viewers, hasMore in
            self.mergePeople(viewers)
            success(viewers.count, hasMore)

        }, failure: { error in
            DDLogError(String(describing: error))
            failure?(error)
        })
    }

    /// Updates a given User with the specified role.
    ///
    /// - Parameters:
    ///     - user: Instance of the person to be updated.
    ///     - role: New role that should be assigned
    ///     - failure: Optional closure, to be executed in case of error
    ///
    /// - Returns: A new Person instance, with the new Role already assigned.
    ///
    func updateUser(_ user: User, role: String, failure: ((Error, User) -> Void)?) -> User {
        guard let managedPerson = managedPersonFromPerson(user) else {
            return user
        }

        // OP Reversal
        let pristineRole = managedPerson.role

        // Hit the Backend
        remote.updateUserRole(siteID, userID: user.ID, newRole: role, success: nil, failure: { error in

            DDLogError("### Error while updating person \(user.ID) in blog \(self.siteID): \(error)")

            guard let managedPerson = self.managedPersonFromPerson(user) else {
                DDLogError("### Person with ID \(user.ID) deleted before update")
                return
            }

            managedPerson.role = pristineRole

            let reloadedPerson = User(managedPerson: managedPerson)
            failure?(error, reloadedPerson)
        })

        // Pre-emptively update the role
        managedPerson.role = role

        return User(managedPerson: managedPerson)
    }

    /// Deletes a given User.
    ///
    /// - Parameters:
    ///     - user: The person that should be deleted
    ///     - success: Closure to be executed in case of success.
    ///     - failure: Closure to be executed on error
    ///
    func deleteUser(_ user: User, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        guard let managedPerson = managedPersonFromPerson(user) else {
            return
        }

        // Hit the Backend
        remote.deleteUser(siteID, userID: user.ID, success: {
            success?()
        }, failure: { error in
            DDLogError("### Error while deleting person \(user.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            self.createManagedPerson(user)

            failure?(error)
        })

        // Pre-emptively nuke the entity
        context.delete(managedPerson)
    }

    /// Deletes a given Follower.
    ///
    /// - Parameters:
    ///     - person: The follower that should be deleted
    ///     - success: Closure to be executed in case of success.
    ///     - failure: Closure to be executed on error
    ///
    func deleteFollower(_ person: Follower, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        guard let managedPerson = managedPersonFromPerson(person) else {
            return
        }

        // Hit the Backend
        remote.deleteFollower(siteID, userID: person.ID, success: {
            success?()
        }, failure: { error in
            DDLogError("### Error while deleting follower \(person.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            self.createManagedPerson(person)

            failure?(error)
        })

        // Pre-emptively nuke the entity
        context.delete(managedPerson)
    }

    /// Deletes a given Viewer.
    ///
    /// - Parameters:
    ///     - person: The follower that should be deleted
    ///     - success: Closure to be executed in case of success.
    ///     - failure: Closure to be executed on error
    ///
    func deleteViewer(_ person: Viewer, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        guard let managedPerson = managedPersonFromPerson(person) else {
            return
        }

        // Hit the Backend
        remote.deleteViewer(siteID, userID: person.ID, success: {
            success?()
        }, failure: { error in
            DDLogError("### Error while deleting viewer \(person.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            self.createManagedPerson(person)

            failure?(error)
        })

        // Pre-emptively nuke the entity
        context.delete(managedPerson)
    }

    /// Nukes all users from Core Data.
    ///
    func removeManagedPeople() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@", NSNumber(value: siteID))
        if let objects = (try? context.fetch(request)) as? [NSManagedObject] {
            objects.forEach { context.delete($0) }
        }
    }

    /// Validates Invitation Recipients.
    ///
    /// - Parameters:
    ///     - usernameOrEmail: Recipient that should be validated.
    ///     - role: Role that would be granted to the recipient.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    func validateInvitation(_ usernameOrEmail: String,
                            role: String,
                            success: @escaping (() -> Void),
                            failure: @escaping ((Error) -> Void)) {
        remote.validateInvitation(siteID,
                                  usernameOrEmail: usernameOrEmail,
                                  role: role,
                                  success: success,
                                  failure: failure)
    }


    /// Sends an Invitation to a specified recipient, to access a Blog.
    ///
    /// - Parameters:
    ///     - usernameOrEmail: Recipient that should be validated.
    ///     - role: Role that would be granted to the recipient.
    ///     - message: String that should be sent to the users.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    func sendInvitation(_ usernameOrEmail: String,
                        role: String,
                        message: String = "",
                        success: @escaping (() -> Void),
                        failure: @escaping ((Error) -> Void)) {
        remote.sendInvitation(siteID,
                              usernameOrEmail: usernameOrEmail,
                              role: role,
                              message: message,
                              success: success,
                              failure: failure)
    }
}

// MARK: - Invite Links Related

extension PeopleService {

    /// Convenience method for retrieving invite links from core data.
    ///
    /// - Parameters:
    ///   - siteID: The ID of the site.
    ///   - success: A success block.
    ///   - failure: A failure block
    ///
    func inviteLinks(_ siteID: Int) -> [InviteLinks] {
        let request = InviteLinks.fetchRequest() as NSFetchRequest<InviteLinks>
        request.predicate = NSPredicate(format: "blog.blogID = %@", NSNumber(value: siteID))
        if let invites = try? context.fetch(request) {
            return invites
        }
        return [InviteLinks]()
    }

    /// Fetch any existing Invite Links
    ///
    /// - Parameters:
    ///   - siteID: The ID of the site.
    ///   - success: A success block.
    ///   - failure: A failure block
    ///
    func fetchInviteLinks(_ siteID: Int,
                          success: @escaping (([InviteLinks]) -> Void),
                          failure: @escaping ((Error) -> Void)) {
        remote.fetchInvites(siteID) { remoteInvites in
            merge(remoteInvites: remoteInvites, for: siteID) {
                let links = inviteLinks(siteID)
                success(links)
            }
        } failure: { error in
            failure(error)
        }
    }

    /// Generate new Invite Links
    ///
    /// - Parameters:
    ///   - siteID: The ID of the site.
    ///   - success: A success block.
    ///   - failure: A failure block
    ///
    func generateInviteLinks(_ siteID: Int,
                             success: @escaping (([InviteLinks]) -> Void),
                             failure: @escaping ((Error) -> Void)) {
        remote.generateInviteLinks(siteID) { _ in
            // Fetch after generation.
            fetchInviteLinks(siteID, success: success, failure: failure)
        } failure: { error in
            failure(error)
        }
    }

    /// Disable existing Invite Links
    ///
    /// - Parameters:
    ///   - siteID: The ID of the site.
    ///   - success: A success block.
    ///   - failure: A failure block
    ///
    func disableInviteLinks(_ siteID: Int,
                            success: @escaping (() -> Void),
                            failure: @escaping ((Error) -> Void)) {
        remote.disableInviteLinks(siteID) { deletedKeys in
            deleteInviteLinks(keys: deletedKeys, for: siteID) {
                success()
            }
        } failure: { (error) in
            failure(error)
        }
    }

    /// Merges an array of RemoteInviteLinks with any existing InviteLinks. InviteLinks
    /// missing from the array of RemoteInviteLinks are deleted.
    ///
    /// - Parameters:
    ///   - remoteInvites: An array of RemoteInviteLinks
    ///   - siteID: The ID of the site to which the InviteLinks belong.
    ///   - onComplete: A completion block that is called after changes are saved to core data.
    ///
    func merge(remoteInvites: [RemoteInviteLink], for siteID: Int, onComplete: @escaping (() -> Void)) {
        let context = ContextManager.shared.newDerivedContext()
        context.perform {
            guard let blog = try? Blog.lookup(withID: siteID, in: context) else {
                DispatchQueue.main.async {
                    onComplete()
                }
                return
            }

            // Delete Stale Items
            let inviteKeys = remoteInvites.map { invite -> String in
                return invite.inviteKey
            }
            deleteMissingInviteLinks(keys: inviteKeys, for: siteID, from: context)

            // Create or Update items
            for remoteInvite in remoteInvites {
                createOrUpdateInviteLink(remoteInvite: remoteInvite, blog: blog, context: context)
            }

            ContextManager.shared.save(context) {
                DispatchQueue.main.async {
                    onComplete()
                }
            }
        }
    }

    /// Deletes InviteLinks whose inviteKeys belong to the supplied array of keys.
    ///
    /// - Parameters:
    ///   - keys: An array of inviteKeys representing InviteLinks to delete.
    ///   - siteID: The ID of the site to which the InviteLinks belong.
    ///   - onComplete: A completion block that is called after changes are saved to core data.
    ///
    func deleteInviteLinks(keys: [String], for siteID: Int, onComplete: @escaping (() -> Void)) {
        let context = ContextManager.shared.newDerivedContext()
        context.perform {

            let request = InviteLinks.fetchRequest() as NSFetchRequest<InviteLinks>
            request.predicate = NSPredicate(format: "inviteKey IN %@ AND blog.blogID = %@", keys, NSNumber(value: siteID))

            do {
                let staleInvites = try context.fetch(request)
                for staleInvite in staleInvites {
                    context.delete(staleInvite)
                }
            } catch {
                DDLogError("Error fetching stale invite links: \(error)")
            }

            ContextManager.shared.save(context) {
                DispatchQueue.main.async {
                    onComplete()
                }
            }
        }
    }

    /// Markes for deletion InviteLinks whose inviteKeys are not included in the supplied array of keys.
    /// This method does not save changes to the persistent store.
    ///
    /// - Parameters:
    ///   - keys: An array of inviteKeys representing InviteLinks to keep.
    ///   - siteID: The ID of the site to which the InviteLinks belong.
    ///   - context: The NSManagedObjectContext to operate on. It is assumed this is a background write context.
    ///
    func deleteMissingInviteLinks(keys: [String], for siteID: Int, from context: NSManagedObjectContext) {
        let request = InviteLinks.fetchRequest() as NSFetchRequest<InviteLinks>
        request.predicate = NSPredicate(format: "NOT (inviteKey IN %@) AND blog.blogID = %@", keys, NSNumber(value: siteID))

        do {
            let staleInvites = try context.fetch(request)
            for staleInvite in staleInvites {
                context.delete(staleInvite)
            }
        } catch {
            DDLogError("Error fetching stale invite links: \(error)")
        }
    }

    /// Updates an existing InviteLinks record, or inserts a new record into the specified NSManagedObjectContext.
    /// This method does not save changes to the persistent store.
    ///
    /// - Parameters:
    ///   - remoteInvite: The RemoteInviteLink that needs to be stored.
    ///   - blog: The blog instance to which the InviteLinks belong.
    ///   - context: The NSManagedObjectContext to operate on. It is assumed this is a background write context.
    ///
    func createOrUpdateInviteLink(remoteInvite: RemoteInviteLink, blog: Blog, context: NSManagedObjectContext) {
        let request = InviteLinks.fetchRequest() as NSFetchRequest<InviteLinks>
        request.predicate = NSPredicate(format: "inviteKey = %@ AND blog = %@", remoteInvite.inviteKey, blog)

        if let invite = try? context.fetch(request).first ?? InviteLinks(context: context) {
            invite.blog = blog
            invite.expiry = remoteInvite.expiry
            invite.groupInvite = remoteInvite.groupInvite
            invite.inviteDate = remoteInvite.inviteDate
            invite.inviteKey = remoteInvite.inviteKey
            invite.isPending = remoteInvite.isPending
            invite.link = remoteInvite.link
            invite.role = remoteInvite.role
        }
    }

}


// MARK: - Private Methods

private extension PeopleService {
    /// Updates the Core Data collection of users, to match with the array of People received.
    ///
    func mergePeople<T: Person>(_ remotePeople: [T]) {
        for remotePerson in remotePeople {
            if let existingPerson = managedPersonFromPerson(remotePerson) {
                existingPerson.updateWith(remotePerson)
                DDLogDebug("Updated person \(existingPerson)")
            } else {
                createManagedPerson(remotePerson)
            }
        }
    }

    /// Retrieves the collection of users, persisted in Core Data, associated with the current blog.
    ///
    func loadPeople<T: Person>(_ siteID: Int, type: T.Type) -> [T] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND kind = %@",
                                        NSNumber(value: siteID as Int),
                                        NSNumber(value: type.kind.rawValue as Int))
        let results: [ManagedPerson]
        do {
            results = try context.fetch(request) as! [ManagedPerson]
        } catch {
            DDLogError("Error fetching all people: \(error)")
            results = []
        }

        return results.map { return T(managedPerson: $0) }
    }

    /// Retrieves a Person from Core Data, with the specifiedID.
    ///
    func managedPersonFromPerson(_ person: Person) -> ManagedPerson? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@ AND kind = %@",
                                                NSNumber(value: siteID as Int),
                                                NSNumber(value: person.ID as Int),
                                                NSNumber(value: type(of: person).kind.rawValue as Int))
        request.fetchLimit = 1

        let results = (try? context.fetch(request) as? [ManagedPerson]) ?? []
        return results.first
    }

    /// Nukes the set of users, from Core Data, with the specified ID's.
    ///
    func removeManagedPeopleWithIDs<T: Person>(_ ids: Set<Int>, type: T.Type) {
        if ids.isEmpty {
            return
        }

        let numberIDs = ids.map { return NSNumber(value: $0 as Int) }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND kind = %@ AND userID IN %@",
                                        NSNumber(value: siteID as Int),
                                        NSNumber(value: type.kind.rawValue as Int),
                                        numberIDs)

        let objects = (try? context.fetch(request) as? [NSManagedObject]) ?? []
        for object in objects {
            DDLogDebug("Removing person: \(object)")
            context.delete(object)
        }
    }

    /// Inserts a new Person instance into Core Data, with the specified payload.
    ///
    func createManagedPerson<T: Person>(_ person: T) {
        let managedPerson = NSEntityDescription.insertNewObject(forEntityName: "Person", into: context) as! ManagedPerson
        managedPerson.updateWith(person)
        managedPerson.creationDate = Date()
        DDLogDebug("Created person \(managedPerson)")
    }
}
