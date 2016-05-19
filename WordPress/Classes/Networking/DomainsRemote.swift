import Foundation

class DomainsRemote: ServiceRemoteREST {
    enum Error: ErrorType {
        case DecodeError
    }

    func getDomainsForSite(siteID: Int, success: [Domain] -> Void, failure: ErrorType -> Void) {
        let endpoint = "sites/\(siteID)/domains"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
                parameters: nil,
                success: {
                    _, response in
                    do {
                        try success(mapDomainsResponse(response))
                    } catch {
                        DDLogSwift.logError("Error parsing domains response (\(error)): \(response)")
                        failure(error)
                    }
            }, failure: {
                _, error in
                failure(error)
        })
    }
}

private func mapDomainsResponse(response: AnyObject) throws -> [Domain] {
    guard let json = response as? [String: AnyObject],
        let domainsJson = json["domains"] as? [[String: AnyObject]] else {
            throw DomainsRemote.Error.DecodeError
    }

    let domains = try domainsJson.map { domainJson -> Domain in

        guard let domainName = domainJson["domain"] as? String,
            let isPrimary = domainJson["primary_domain"] as? Bool else {
                throw DomainsRemote.Error.DecodeError
        }

        return Domain(domain: domainName, isPrimaryDomain: isPrimary, domainType: domainTypeFromDomainJSON(domainJson))
    }

    return domains
}

private func domainTypeFromDomainJSON(domainJson: [String: AnyObject]) -> DomainType {
    if let type = domainJson["type"] as? String
        where type == "redirect" {
        return .SiteRedirect
    }

    if let wpComDomain = domainJson["wpcom_domain"] as? Bool
        where wpComDomain == true {
        return .WPCom
    }

    if let hasRegistration = domainJson["has_registration"] as? Bool
        where hasRegistration == true {
        return .Registered
    }

    return .Mapped
}

struct DomainsService {
    let remote: DomainsRemote
    let blog: Blog
    let siteID: Int

    private let context = ContextManager.sharedInstance().mainContext

    init(blog: Blog) {
        precondition(blog.dotComID != nil)

        remote = DomainsRemote(api: blog.restApi())
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

        let remoteDomainNames = Set(remoteDomains.map({ $0.domain }))
        let localDomainNames = Set(localDomains.map({ $0.domain }))

        let removedDomainNames = localDomainNames.subtract(remoteDomainNames)
        removeDomains(removedDomainNames)

        // Let's try to only update objects that have changed
        let remoteChanges = remoteDomains.filter {
            return !localDomains.contains($0)
        }

        for remoteDomain in remoteChanges {
            if let existingDomain = managedDomainWithName(remoteDomain.domain) {
                existingDomain.updateWith(remoteDomain, blog: blog)
                DDLogSwift.logDebug("Updated domain \(existingDomain)")
            } else {
                createManagedDomain(remoteDomain)
            }
        }

        ContextManager.sharedInstance().saveContext(context)
    }

    private func managedDomainWithName(name: String) -> ManagedDomain? {
        let request = NSFetchRequest(entityName: Domain.entityName)
        request.predicate = NSPredicate(format: "blog = %@ AND domain = %@", blog, name)
        request.fetchLimit = 1
        let results = (try? context.executeFetchRequest(request) as! [ManagedDomain]) ?? []
        return results.first
    }

    private func createManagedDomain(domain: Domain) {
        let managedDomain = NSEntityDescription.insertNewObjectForEntityForName(Domain.entityName, inManagedObjectContext: context) as! ManagedDomain
        managedDomain.updateWith(domain, blog: blog)
        DDLogSwift.logDebug("Created domain \(managedDomain)")
    }

    private func blogDomains() -> [Domain] {
        let request = NSFetchRequest(entityName: Domain.entityName)
        request.predicate = NSPredicate(format: "%K == %@", "blog", blog)

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
        let request = NSFetchRequest(entityName: Domain.entityName)
        request.predicate = NSPredicate(format: "blog = %@ AND domain IN %@", blog, domainNames)
        let objects = (try? context.executeFetchRequest(request) as! [NSManagedObject]) ?? []
        for object in objects {
            DDLogSwift.logDebug("Removing domain: \(object)")
            context.deleteObject(object)
        }
    }
}
