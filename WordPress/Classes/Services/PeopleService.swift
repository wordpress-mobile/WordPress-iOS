import Foundation


/// Service providing access to the People Management WordPress.com API.
///
struct PeopleService {
    typealias Role = Person.Role

    let remote: PeopleRemote
    let siteID: Int

    private let context = ContextManager.sharedInstance().mainContext


    /// Designated Initializer.
    ///
    /// -   Parameters:
    ///     - blog: Target Blog Instance
    ///
    init?(blog: Blog) {
        guard let api = blog.restApi() else {
            return nil
        }

        remote = PeopleRemote(api: api)
        siteID = blog.dotComID as! Int
    }


    /// Refreshes the team of Users associated to a blog.
    ///
    /// -   Parameters:
    ///     - completion: Closure to be executed on completion.
    ///
    func refreshTeam(completion: (Bool) -> Void) {
        remote.getTeamFor(siteID,
            success: { people in

                self.mergeTeam(people)
                completion(true)
            },
            failure: { error in
                DDLogSwift.logError(String(error))
                completion(false)
        })
    }

    /// Updates a given person with the specified role.
    ///
    /// -   Parameters:
    ///     - person: Instance of the person to be updated.
    ///     - role: New role that should be assigned
    ///     - failure: Optional closure, to be executed in case of error
    ///
    /// -   Returns: A new Person instance, with the new Role already assigned.
    ///
    func updatePerson(person: Person, role: Role, failure: ((ErrorType, Person) -> ())?) -> Person {
        guard let managedPerson = managedPersonWithID(person.ID) else {
            return person
        }

        // OP Reversal
        let pristineRole = managedPerson.role

        // Hit the Backend
        remote.updatePersonFor(siteID, personID: person.ID, newRole: role, success: nil, failure: { error in

            DDLogSwift.logError("### Error while updating person \(person.ID) in blog \(self.siteID): \(error)")

            guard let managedPerson = self.managedPersonWithID(person.ID) else {
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

    /// Retrieves the collection of Roles, available for a given site
    ///
    /// -   Parameters:
    ///     - success: Closure to be executed in case of success. The collection of Roles will be passed on.
    ///     - failure: Closure to be executed in case of error
    ///
    func loadAvailableRoles(success: ([Role] -> Void), failure: (ErrorType -> Void)) {
        remote.getAvailableRolesFor(siteID, success: { roles in
            success(roles)
        }, failure: { error in
            failure(error)
        })
    }
}


/// Encapsulates all of the PeopleService Private Methods.
///
private extension PeopleService {
    /// Updates the Core Data collection of users, to match with the array of People received.
    ///
    func mergeTeam(people: People) {
        let remotePeople = people
        let localPeople = allPeople()

        let remoteIDs = Set(remotePeople.map({ $0.ID }))
        let localIDs = Set(localPeople.map({ $0.ID }))

        let removedIDs = localIDs.subtract(remoteIDs)
        removeManagedPeopleWithIDs(removedIDs)

        // Let's try to only update objects that have changed
        let remoteChanges = remotePeople.filter {
            return !localPeople.contains($0)
        }
        for remotePerson in remoteChanges {
            if let existingPerson = managedPersonWithID(remotePerson.ID) {
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
    func allPeople() -> People {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@", NSNumber(integer: siteID))
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
    func managedPersonWithID(id: Int) -> ManagedPerson? {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@", NSNumber(integer: siteID), NSNumber(integer: id))
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
