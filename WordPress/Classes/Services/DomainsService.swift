import Foundation
import CocoaLumberjack
import WordPressKit
import CoreData

struct FullyQuotedDomainSuggestion {
    public let domainName: String
    public let productID: Int?
    public let supportsPrivacy: Bool?
    public let costString: String
    public let saleCostString: String?

    /// Maps the suggestion to a DomainSuggestion we can use with out APIs.
    func remoteSuggestion() -> DomainSuggestion {
        DomainSuggestion(domainName: domainName,
                         productID: productID,
                         supportsPrivacy: supportsPrivacy,
                         costString: costString)
    }
}

struct DomainsService {
    typealias RemoteDomainSuggestion = DomainSuggestion

    let remote: DomainsServiceRemote
    let productsRemote: ProductServiceRemote

    fileprivate let context: NSManagedObjectContext

    init(managedObjectContext context: NSManagedObjectContext, remote: DomainsServiceRemote) {
        self.context = context
        self.remote = remote
        self.productsRemote = ProductServiceRemote(restAPI: remote.wordPressComRestApi)
    }

    /// Refreshes the domains for the specified site.  Since this method takes care of merging the new data into our local
    /// persistance layer making it useful to call even without knowing the result, the completion closure is optional.
    ///
    /// - Parameters:
    ///     - siteID: the ID of the site to refresh the domains for.
    ///     - completion: the result of the refresh request.
    ///
    func refreshDomains(siteID: Int, completion: ((Result<Void, Error>) -> Void)? = nil) {
        remote.getDomainsForSite(siteID, success: { domains in
            self.mergeDomains(domains, forSite: siteID)
            completion?(.success(()))
        }, failure: { error in
            completion?(.failure(error))
        })
    }

    func getDomainSuggestions(query: String,
                              segmentID: Int64? = nil,
                              quantity: Int? = nil,
                              domainSuggestionType: DomainsServiceRemote.DomainSuggestionType? = nil,
                              success: @escaping ([DomainSuggestion]) -> Void,
                              failure: @escaping (Error) -> Void) {
        let request = DomainSuggestionRequest(query: query, segmentID: segmentID, quantity: quantity, suggestionType: domainSuggestionType)

        remote.getDomainSuggestions(request: request,
                                    success: { suggestions in
            let sorted = self.sortedSuggestions(suggestions, query: query)
            success(sorted)
        }) { error in
            failure(error)
        }
    }

    func getFullyQuotedDomainSuggestions(query: String,
                                         segmentID: Int64? = nil,
                                         quantity: Int? = nil,
                                         domainSuggestionType: DomainsServiceRemote.DomainSuggestionType? = nil,
                                         success: @escaping ([FullyQuotedDomainSuggestion]) -> Void,
                                         failure: @escaping (Error) -> Void) {

        productsRemote.getProducts { result in
            switch result {
            case .failure(let error):
                failure(error)
            case .success(let products):
                getDomainSuggestions(query: query, segmentID: segmentID, quantity: quantity, domainSuggestionType: domainSuggestionType, success: { domainSuggestions in

                    success(domainSuggestions.map { remoteSuggestion in
                        let saleCostString = products.first() {
                            $0.id == remoteSuggestion.productID
                        }?.saleCostForDisplay()

                        return FullyQuotedDomainSuggestion(
                            domainName: remoteSuggestion.domainName,
                            productID: remoteSuggestion.productID,
                            supportsPrivacy: remoteSuggestion.supportsPrivacy,
                            costString: remoteSuggestion.costString,
                            saleCostString: saleCostString)
                    })
                }, failure: failure)
            }
        }
    }
/*
    func getDomainSuggestions(query: String,
                              quantity: Int? = nil,
                              domainSuggestionType: DomainSuggestionType = .onlyWordPressDotCom,
                              success: @escaping ([DomainSuggestion]) -> Void,
                              failure: @escaping (Error) -> Void) {
        let request = DomainSuggestionRequest(query: query, quantity: quantity)
        
        remote.getDomainSuggestions(base: base,
                                    quantity: quantity,
                                    domainSuggestionType: domainSuggestionType,
                                    success: { suggestions in
            let sorted = self.sortedSuggestions(suggestions, forBase: base)
            success(sorted)
        }) { error in
            failure(error)
        }
    }*/

    // If any of the suggestions matches the base exactly,
    // then sort that suggestion up to the top of the list.
    fileprivate func sortedSuggestions(_ suggestions: [RemoteDomainSuggestion], query: String) -> [RemoteDomainSuggestion] {
        let normalizedQuery = query.lowercased().replacingMatches(of: " ", with: "")

        var filteredSuggestions = suggestions
        if let matchedSuggestionIndex = suggestions.firstIndex(where: { $0.subdomain == query || $0.subdomain == normalizedQuery }) {
            let matchedSuggestion = filteredSuggestions.remove(at: matchedSuggestionIndex)
            filteredSuggestions.insert(matchedSuggestion, at: 0)
        }

        return filteredSuggestions
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
                create(remoteDomain, forSite: siteID)
            }
        }

        ContextManager.sharedInstance().saveContextAndWait(context)
    }

    fileprivate func blogForSiteID(_ siteID: Int) -> Blog? {
        guard let blog = try? Blog.lookup(withID: siteID, in: context) else {
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
        let results = (try? context.fetch(request) as? [ManagedDomain]) ?? []
        return results.first
    }

    func create(_ domain: Domain, forSite siteID: Int) {
        guard let blog = blogForSiteID(siteID) else { return }

        let managedDomain = NSEntityDescription.insertNewObject(forEntityName: ManagedDomain.entityName(), into: context) as! ManagedDomain
        managedDomain.updateWith(domain, blog: blog)
        DDLogDebug("Created domain \(managedDomain)")

        ContextManager.sharedInstance().saveContextAndWait(context)
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
        let objects = (try? context.fetch(request) as? [NSManagedObject]) ?? []
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
