import Foundation

struct DomainsService {
    let remote: DomainsServiceRemote

    private let context: NSManagedObjectContext

    init(managedObjectContext context: NSManagedObjectContext, remote: DomainsServiceRemote) {
        self.context = context
        self.remote = remote
    }

    func refreshDomainsForSite(siteID: Int, completion: (Bool) -> Void) {
        remote.getDomainsForSite(siteID, success: { domains in
            self.mergeDomains(domains, forSite: siteID)
            completion(true)
            }, failure: { error in
                completion(false)
        })
    }

    private func mergeDomains(domains: [Domain], forSite siteID: Int) {
        let remoteDomains = domains
        let localDomains = domainsForSite(siteID)

        let remoteDomainNames = Set(remoteDomains.map({ $0.domainName }))
        let localDomainNames = Set(localDomains.map({ $0.domainName }))

        let removedDomainNames = localDomainNames.subtract(remoteDomainNames)
        removeDomains(removedDomainNames, fromSite: siteID)

        // Let's try to only update objects that have changed
        let remoteChanges = remoteDomains.filter {
            return !localDomains.contains($0)
        }

        for remoteDomain in remoteChanges {
            if let existingDomain = managedDomainWithName(remoteDomain.domainName, forSite: siteID),
                let blog = blogForSiteID(siteID) {
                existingDomain.updateWith(remoteDomain, blog: blog)
                DDLogSwift.logDebug("Updated domain \(existingDomain)")
            } else {
                createManagedDomain(remoteDomain, forSite: siteID)
            }
        }

        ContextManager.sharedInstance().saveContext(context)
    }

    private func blogForSiteID(siteID: Int) -> Blog? {
        let service = BlogService(managedObjectContext: context)

        guard let blog = service.blogByBlogId(siteID) else {
            let error = "Tried to obtain a Blog for a non-existing site (ID: \(siteID))"
            assertionFailure(error)
            DDLogSwift.logError(error)
            return nil
        }

        return blog
    }

    private func managedDomainWithName(domainName: String, forSite siteID: Int) -> ManagedDomain? {
        guard let blog = blogForSiteID(siteID) else { return nil }

        let request = NSFetchRequest(entityName: ManagedDomain.entityName)
        request.predicate = NSPredicate(format: "%K = %@ AND %K = %@", ManagedDomain.Relationships.blog, blog, ManagedDomain.Attributes.domainName, domainName)
        request.fetchLimit = 1
        let results = (try? context.executeFetchRequest(request) as! [ManagedDomain]) ?? []
        return results.first
    }

    private func createManagedDomain(domain: Domain, forSite siteID: Int) {
        guard let blog = blogForSiteID(siteID) else { return }

        let managedDomain = NSEntityDescription.insertNewObjectForEntityForName(ManagedDomain.entityName, inManagedObjectContext: context) as! ManagedDomain
        managedDomain.updateWith(domain, blog: blog)
        DDLogSwift.logDebug("Created domain \(managedDomain)")
    }

    private func domainsForSite(siteID: Int) -> [Domain] {
        guard let blog = blogForSiteID(siteID) else { return [] }

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

    private func removeDomains(domainNames: Set<String>, fromSite siteID: Int) {
        guard let blog = blogForSiteID(siteID) else { return }

        let request = NSFetchRequest(entityName: ManagedDomain.entityName)
        request.predicate = NSPredicate(format: "%K = %@ AND %K IN %@", ManagedDomain.Relationships.blog, blog, ManagedDomain.Attributes.domainName, domainNames)
        let objects = (try? context.executeFetchRequest(request) as! [NSManagedObject]) ?? []
        for object in objects {
            DDLogSwift.logDebug("Removing domain: \(object)")
            context.deleteObject(object)
        }
    }
}

extension DomainsService {
    init(managedObjectContext context: NSManagedObjectContext, account: WPAccount) {
        self.init(managedObjectContext: context, remote: DomainsServiceRemote(api: account.restApi))
    }
}
