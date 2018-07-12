import Foundation
import CocoaLumberjack
import WordPressKit

struct DomainsService {
    let remote: DomainsServiceRemote

    fileprivate let context: NSManagedObjectContext

    init(managedObjectContext context: NSManagedObjectContext, remote: DomainsServiceRemote) {
        self.context = context
        self.remote = remote
    }

    func refreshDomainsForSite(_ siteID: Int, completion: @escaping (Bool) -> Void) {
        remote.getDomainsForSite(siteID, success: { domains in
            self.mergeDomains(domains, forSite: siteID)
            completion(true)
            }, failure: { error in
                completion(false)
        })
    }

    func getDomainSuggestions(base: String,
                              includeWordPressDotCom: Bool = true,
                              onlyWordPressDotCom: Bool = true,
                              success: @escaping ([String]) -> Void, failure: @escaping (Error) -> Void) {
        remote.getDomainSuggestions(base: base,
                                    includeWordPressDotCom: includeWordPressDotCom,
                                    onlyWordPressDotCom: onlyWordPressDotCom,
                                    success: { suggestions in
            success(suggestions)
        }) { error in
            failure(error)
        }
    }

    fileprivate func mergeDomains(_ domains: [Domain], forSite siteID: Int) {
        let remoteDomains = domains
        let localDomains = domainsForSite(siteID)

        let remoteDomainNames = Set(remoteDomains.map({ $0.domainName }))
        let localDomainNames = Set(localDomains.map({ $0.domainName }))

        let removedDomainNames = localDomainNames.subtracting(remoteDomainNames)
        removeDomains(removedDomainNames, fromSite: siteID)

        // Let's try to only update objects that have changed
        let remoteChanges = remoteDomains.filter {
            return !localDomains.contains($0)
        }

        for remoteDomain in remoteChanges {
            if let existingDomain = managedDomainWithName(remoteDomain.domainName, forSite: siteID),
                let blog = blogForSiteID(siteID) {
                existingDomain.updateWith(remoteDomain, blog: blog)
                DDLogDebug("Updated domain \(existingDomain)")
            } else {
                createManagedDomain(remoteDomain, forSite: siteID)
            }
        }

        ContextManager.sharedInstance().saveContextAndWait(context)
    }

    fileprivate func blogForSiteID(_ siteID: Int) -> Blog? {
        let service = BlogService(managedObjectContext: context)

        guard let blog = service.blog(byBlogId: NSNumber(value: siteID)) else {
            let error = "Tried to obtain a Blog for a non-existing site (ID: \(siteID))"
            assertionFailure(error)
            DDLogError(error)
            return nil
        }

        return blog
    }

    fileprivate func managedDomainWithName(_ domainName: String, forSite siteID: Int) -> ManagedDomain? {
        guard let blog = blogForSiteID(siteID) else { return nil }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDomain.entityName())
        request.predicate = NSPredicate(format: "%K = %@ AND %K = %@", ManagedDomain.Relationships.blog, blog, ManagedDomain.Attributes.domainName, domainName)
        request.fetchLimit = 1
        let results = (try? context.fetch(request) as! [ManagedDomain]) ?? []
        return results.first
    }

    fileprivate func createManagedDomain(_ domain: Domain, forSite siteID: Int) {
        guard let blog = blogForSiteID(siteID) else { return }

        let managedDomain = NSEntityDescription.insertNewObject(forEntityName: ManagedDomain.entityName(), into: context) as! ManagedDomain
        managedDomain.updateWith(domain, blog: blog)
        DDLogDebug("Created domain \(managedDomain)")
    }

    fileprivate func domainsForSite(_ siteID: Int) -> [Domain] {
        guard let blog = blogForSiteID(siteID) else { return [] }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDomain.entityName())
        request.predicate = NSPredicate(format: "%K == %@", ManagedDomain.Relationships.blog, blog)

        let domains: [ManagedDomain]
        do {
            domains = try context.fetch(request) as! [ManagedDomain]
        } catch {
            DDLogError("Error fetching domains: \(error)")
            domains = []
        }

        return domains.map { Domain(managedDomain: $0) }
    }

    fileprivate func removeDomains(_ domainNames: Set<String>, fromSite siteID: Int) {
        guard let blog = blogForSiteID(siteID) else { return }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDomain.entityName())
        request.predicate = NSPredicate(format: "%K = %@ AND %K IN %@", ManagedDomain.Relationships.blog, blog, ManagedDomain.Attributes.domainName, domainNames)
        let objects = (try? context.fetch(request) as! [NSManagedObject]) ?? []
        for object in objects {
            DDLogDebug("Removing domain: \(object)")
            context.delete(object)
        }
    }
}

extension DomainsService {
    init(managedObjectContext context: NSManagedObjectContext, account: WPAccount) {
        self.init(managedObjectContext: context, remote: DomainsServiceRemote(wordPressComRestApi: account.wordPressComRestApi))
    }
}
