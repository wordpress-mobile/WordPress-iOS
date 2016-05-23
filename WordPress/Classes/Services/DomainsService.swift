import Foundation

struct DomainsService {
    let remote: DomainsServiceRemote
    let blog: Blog
    let siteID: Int

    private let context = ContextManager.sharedInstance().mainContext

    init(blog: Blog) {
        precondition(blog.dotComID != nil)

        remote = DomainsServiceRemote(api: blog.restApi())
        self.blog = blog
        siteID = Int(blog.dotComID!)
    }

    func refreshBlogDomains(completion: (Bool) -> Void) {
        remote.getDomainsForSite(siteID, success: { domains in
            self.mergeDomains(domains)
            }, failure: { error in
                completion(false)
        })
    }

    private func mergeDomains(domains: [Domain]) {
        let remoteDomains = domains
        let localDomains = blogDomains()

        let remoteDomainNames = Set(remoteDomains.map({ $0.domainName }))
        let localDomainNames = Set(localDomains.map({ $0.domainName }))

        let removedDomainNames = localDomainNames.subtract(remoteDomainNames)
        removeDomains(removedDomainNames)

        // Let's try to only update objects that have changed
        let remoteChanges = remoteDomains.filter {
            return !localDomains.contains($0)
        }

        for remoteDomain in remoteChanges {
            if let existingDomain = managedDomainWithName(remoteDomain.domainName) {
                existingDomain.updateWith(remoteDomain, blog: blog)
                DDLogSwift.logDebug("Updated domain \(existingDomain)")
            } else {
                createManagedDomain(remoteDomain)
            }
        }

        ContextManager.sharedInstance().saveContext(context)
    }

    private func managedDomainWithName(domainName: String) -> ManagedDomain? {
        let request = NSFetchRequest(entityName: ManagedDomain.entityName)
        request.predicate = NSPredicate(format: "%K = %@ AND %K = %@", ManagedDomain.Relationships.blog, blog, ManagedDomain.Attributes.domainName, domainName)
        request.fetchLimit = 1
        let results = (try? context.executeFetchRequest(request) as! [ManagedDomain]) ?? []
        return results.first
    }

    private func createManagedDomain(domain: Domain) {
        let managedDomain = NSEntityDescription.insertNewObjectForEntityForName(ManagedDomain.entityName, inManagedObjectContext: context) as! ManagedDomain
        managedDomain.updateWith(domain, blog: blog)
        DDLogSwift.logDebug("Created domain \(managedDomain)")
    }

    private func blogDomains() -> [Domain] {
        let request = NSFetchRequest(entityName: ManagedDomain.entityName)
        request.predicate = NSPredicate(format: "%K == %@", ManagedDomain.Relationships.blog, blog)

        let domains: [ManagedDomain]
        do {
            domains = try context.executeFetchRequest(request) as! [ManagedDomain]
        } catch {
            DDLogSwift.logError("Error fetching domains: \(error)")
            domains = []
        }

        return domains.map { Domain(managedDomain: $0) }
    }

    private func removeDomains(domainNames: Set<String>) {
        let request = NSFetchRequest(entityName: ManagedDomain.entityName)
        request.predicate = NSPredicate(format: "%K = %@ AND %K IN %@", ManagedDomain.Relationships.blog, blog, ManagedDomain.Attributes.domainName, domainNames)
        let objects = (try? context.executeFetchRequest(request) as! [NSManagedObject]) ?? []
        for object in objects {
            DDLogSwift.logDebug("Removing domain: \(object)")
            context.deleteObject(object)
        }
    }
}
