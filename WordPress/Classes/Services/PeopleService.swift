import Foundation


/// Service providing access to the People Management WordPress.com API.
///
struct PeopleService {
    typealias Role = Person.Role

    let siteID: Int

    private let context = ContextManager.sharedInstance().mainContext
    private let remote: PeopleRemote


    /// Designated Initializer.
    ///
    /// - Parameter blog: Target Blog Instance
    ///
    init?(blog: Blog) {
        guard let api = blog.restApi(), dotComID = blog.dotComID as? Int else {
            return nil
        }

        remote = PeopleRemote(api: api)
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


    /// Updates a given person with the specified role.
    ///
    /// - Parameters:
    ///     - person: Instance of the person to be updated.
    ///     - role: New role that should be assigned
    ///     - failure: Optional closure, to be executed in case of error
    ///
    /// - Returns: A new Person instance, with the new Role already assigned.
    ///
    func updatePerson(person: Person, role: Role, failure: ((ErrorType, Person) -> Void)?) -> Person {
        guard let managedPerson = managedPersonFromPerson(person) else {
            return person
        }

        // OP Reversal
        let pristineRole = managedPerson.role

        // Hit the Backend
        remote.updateUserRole(siteID, personID: person.ID, newRole: role, success: nil, failure: { error in

            DDLogSwift.logError("### Error while updating person \(person.ID) in blog \(self.siteID): \(error)")

            guard let managedPerson = self.managedPersonFromPerson(person) else {
                DDLogSwift.logError("### Person with ID \(person.ID) deleted before update")
                return
            }

            managedPerson.role = pristineRole
            ContextManager.sharedInstance().saveContext(self.context)

            let reloadedPerson = Person(managedPerson: managedPerson)
            failure?(error, reloadedPerson)
        })

        // Pre-emptively update the role
        managedPerson.role = role.description
        ContextManager.sharedInstance().saveContext(context)

        return Person(managedPerson: managedPerson)
    }

    /// Deletes or removes a given person.
    ///
    /// - Parameters:
    ///     - person: The person that should be deleted
    ///     - failure: Closure to be executed on error
    ///
    func deletePerson(person: Person, failure: (ErrorType -> Void)? = nil) {
        guard let managedPerson = managedPersonFromPerson(person) else {
            return
        }

        // Hit the Backend
        remote.deleteUser(siteID, personID: person.ID, failure: { error in

            DDLogSwift.logError("### Error while deleting person \(person.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            self.createManagedPerson(person)
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
    func mergeUsers(users: People) {
        let localUsers = loadPeople(followers: false)
        mergePeople(users, localPeople: localUsers)
    }

    /// Updates the local collection of Followers, with the (fresh) remote version.
    ///
    func mergeFollowers(followers: People) {
        let localFollowers = loadPeople(followers: true)
        mergePeople(followers, localPeople: localFollowers)
    }

    /// Updates the Core Data collection of users, to match with the array of People received.
    ///
    func mergePeople(remotePeople: People, localPeople: People) {
        let remoteIDs = Set(remotePeople.map({ $0.ID }))
        let localIDs = Set(localPeople.map({ $0.ID }))

        let removedIDs = localIDs.subtract(remoteIDs)
        removeManagedPeopleWithIDs(removedIDs)

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
    func loadPeople(followers isFollower: Bool) -> People {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND isFollower = %@", NSNumber(integer: siteID), isFollower)
        let results: [ManagedPerson]
        do {
            results = try context.executeFetchRequest(request) as! [ManagedPerson]
        } catch {
            DDLogSwift.logError("Error fetching all people: \(error)")
            results = []
        }

        return results.map { return Person(managedPerson: $0) }
    }

    /// Retrieves a Person from Core Data, with the specifiedID.
    ///
    func managedPersonFromPerson(person: Person) -> ManagedPerson? {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@ AND isFollower = %@",
                                                NSNumber(integer: siteID),
                                                NSNumber(integer: person.ID),
                                                NSNumber(bool: person.isFollower))
        request.fetchLimit = 1

        let results = (try? context.executeFetchRequest(request) as! [ManagedPerson]) ?? []
        return results.first
    }

    /// Nukes the set of users, from Core Data, with the specified ID's.
    ///
    func removeManagedPeopleWithIDs(ids: Set<Int>) {
        if ids.isEmpty {
            return
        }

        let numberIDs = ids.map { return NSNumber(integer: $0) }
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID IN %@", NSNumber(integer: siteID), numberIDs)
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
