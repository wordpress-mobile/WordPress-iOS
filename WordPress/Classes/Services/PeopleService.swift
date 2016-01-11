import Foundation

struct PeopleService {
    let remote: PeopleRemote
    let siteID: Int

    private let context = ContextManager.sharedInstance().mainContext

    init(blog: Blog) {
        remote = PeopleRemote(api: blog.restApi())
        siteID = blog.dotComID as Int
    }

    func refreshTeam(completion: (Bool) -> Void) {
        remote.getTeamFor(siteID,
            success: {
                (people) -> () in

                self.mergeTeam(people)
                completion(true)
            },
            failure: {
                (error) -> () in

                DDLogSwift.logError(String(error))
                completion(false)
        })
    }

    private func mergeTeam(people: People) {
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

    private func allPeople() -> People {
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

    private func managedPersonWithID(id: Int) -> ManagedPerson? {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@", NSNumber(integer: siteID), NSNumber(integer: id))
        request.fetchLimit = 1
        let results = (try? context.executeFetchRequest(request) as! [ManagedPerson]) ?? []
        return results.first
    }

    private func removeManagedPeopleWithIDs(ids: Set<Int>) {
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

    private func createManagedPerson(person: Person) {
        let managedPerson = NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: context) as! ManagedPerson
        managedPerson.updateWith(person)
        DDLogSwift.logDebug("Created person \(managedPerson)")
    }
}