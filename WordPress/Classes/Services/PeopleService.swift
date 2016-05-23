import Foundation


/// Service providing access to the People Management WordPress.com API.
///
struct PeopleService {
    /// MARK: - Public Properties
    ///
    let siteID: Int

    /// MARK: - Private Properties
    ///
    private let context = ContextManager.sharedInstance().mainContext
    private let remote: PeopleRemote


    /// Designated Initializer.
    ///
    /// - Parameter blog: Target Blog Instance
    ///
    init?(blog: Blog) {
        guard let api = blog.wordPressComRestApi(), dotComID = blog.dotComID as? Int else {
            return nil
        }

        remote = PeopleRemote(wordPressComRestApi: api)
        siteID = dotComID
    }

    /// Refreshes the Users + Followers associated to the current blog.
    ///
    /// - Parameter completion: Closure to be executed on completion.
    ///
    func refreshPeople(completion: (Bool -> Void)) {
        let group = dispatch_group_create()
        var success = true

        // Load Users
        dispatch_group_enter(group)
        remote.getUsers(siteID, success: { users in
            self.mergeUsers(users)
            dispatch_group_leave(group)

        }, failure: { error in
            DDLogSwift.logError(String(error))
            success = false
            dispatch_group_leave(group)
        })

        // Load Followers
        dispatch_group_enter(group)
        remote.getFollowers(siteID, success: { followers in
            self.mergeFollowers(followers)
            dispatch_group_leave(group)

        }, failure: { error in
            DDLogSwift.logError(String(error))
            success = false
            dispatch_group_leave(group)
        })

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion(success)
        }
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
    func updateUser(user: User, role: Role, failure: ((ErrorType, User) -> Void)?) -> User {
        guard let managedPerson = managedPersonFromPerson(user) else {
            return user
        }

        // OP Reversal
        let pristineRole = managedPerson.role

        // Hit the Backend
        remote.updateUserRole(siteID, userID: user.ID, newRole: role, success: nil, failure: { error in

            DDLogSwift.logError("### Error while updating person \(user.ID) in blog \(self.siteID): \(error)")

            guard let managedPerson = self.managedPersonFromPerson(user) else {
                DDLogSwift.logError("### Person with ID \(user.ID) deleted before update")
                return
            }

            managedPerson.role = pristineRole
            ContextManager.sharedInstance().saveContext(self.context)

            let reloadedPerson = User(managedPerson: managedPerson)
            failure?(error, reloadedPerson)
        })

        // Pre-emptively update the role
        managedPerson.role = role.description
        ContextManager.sharedInstance().saveContext(context)

        return User(managedPerson: managedPerson)
    }

    /// Deletes a given User.
    ///
    /// - Parameters:
    ///     - user: The person that should be deleted
    ///     - failure: Closure to be executed on error
    ///
    func deleteUser(user: User, failure: (ErrorType -> Void)? = nil) {
        guard let managedPerson = managedPersonFromPerson(user) else {
            return
        }

        // Hit the Backend
        remote.deleteUser(siteID, userID: user.ID, failure: { error in

            DDLogSwift.logError("### Error while deleting person \(user.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            self.createManagedPerson(user)
            ContextManager.sharedInstance().saveContext(self.context)

            failure?(error)
        })

        // Pre-emptively nuke the entity
        context.deleteObject(managedPerson)
        ContextManager.sharedInstance().saveContext(context)
    }

    /// Retrieves the collection of Roles, available for a given site
    ///
    /// - Parameters:
    ///     - success: Closure to be executed in case of success. The collection of Roles will be passed on.
    ///     - failure: Closure to be executed in case of error
    ///
    func loadAvailableRoles(success: ([Role] -> Void), failure: (ErrorType -> Void)) {
        remote.getUserRoles(siteID, success: { roles in
            success(roles)

        }, failure: { error in
            failure(error)
        })
    }
}


/// Encapsulates all of the PeopleService Private Methods.
///
private extension PeopleService {
    /// Updates the local collection of Users, with the (fresh) remote version.
    ///
    func mergeUsers(remoteUsers: [User]) {
        let localUsers = loadPeople(siteID, type: User.self)
        mergePeople(remoteUsers, localPeople: localUsers)
    }

    /// Updates the local collection of Followers, with the (fresh) remote version.
    ///
    func mergeFollowers(remoteFollowers: [Follower]) {
        let localFollowers = loadPeople(siteID, type: Follower.self)
        mergePeople(remoteFollowers, localPeople: localFollowers)
    }

    /// Updates the Core Data collection of users, to match with the array of People received.
    ///
    func mergePeople<T : Person>(remotePeople: [T], localPeople: [T]) {
        let remoteIDs = Set(remotePeople.map({ $0.ID }))
        let localIDs = Set(localPeople.map({ $0.ID }))

        let removedIDs = localIDs.subtract(remoteIDs)
        removeManagedPeopleWithIDs(removedIDs, type: T.self)

        for remotePerson in remotePeople {
            if let existingPerson = managedPersonFromPerson(remotePerson) {
                existingPerson.updateWith(remotePerson)
                DDLogSwift.logDebug("Updated person \(existingPerson)")
            } else {
                createManagedPerson(remotePerson)
            }
        }

        ContextManager.sharedInstance().saveContext(context)
    }

    /// Retrieves the collection of users, persisted in Core Data, associated with the current blog.
    ///
    func loadPeople<T : Person>(siteID: Int, type: T.Type) -> [T] {
        let isFollower = type.isFollower
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND isFollower = %@", NSNumber(integer: siteID), isFollower)
        let results: [ManagedPerson]
        do {
            results = try context.executeFetchRequest(request) as! [ManagedPerson]
        } catch {
            DDLogSwift.logError("Error fetching all people: \(error)")
            results = []
        }

        return results.map { return T(managedPerson: $0) }
    }

    /// Retrieves a Person from Core Data, with the specifiedID.
    ///
    func managedPersonFromPerson(person: Person) -> ManagedPerson? {
        let request = NSFetchRequest(entityName: "Person")
        let isFollower = person.dynamicType.isFollower
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@ AND isFollower = %@",
                                                NSNumber(integer: siteID),
                                                NSNumber(integer: person.ID),
                                                NSNumber(bool: isFollower))
        request.fetchLimit = 1

        let results = (try? context.executeFetchRequest(request) as! [ManagedPerson]) ?? []
        return results.first
    }

    /// Nukes the set of users, from Core Data, with the specified ID's.
    ///
    func removeManagedPeopleWithIDs<T : Person>(ids: Set<Int>, type: T.Type) {
        if ids.isEmpty {
            return
        }

        let follower = type.isFollower
        let numberIDs = ids.map { return NSNumber(integer: $0) }
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND isFollower = %@ AND userID IN %@",
                                        NSNumber(integer: siteID),
                                        NSNumber(bool: follower),
                                        numberIDs)

        let objects = (try? context.executeFetchRequest(request) as! [NSManagedObject]) ?? []
        for object in objects {
            DDLogSwift.logDebug("Removing person: \(object)")
            context.deleteObject(object)
        }
    }

    /// Inserts a new Person instance into Core Data, with the specified payload.
    ///
    func createManagedPerson(person: Person) {
        let managedPerson = NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: context) as! ManagedPerson
        managedPerson.updateWith(person)
        DDLogSwift.logDebug("Created person \(managedPerson)")
    }
}
