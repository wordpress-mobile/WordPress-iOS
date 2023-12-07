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

    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack, remote: DomainsServiceRemote) {
        self.coreDataStack = coreDataStack
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
            self.coreDataStack.performAndSave({ context in
                self.mergeDomains(domains, forSite: siteID, in: context)
            }, completion: {
                completion?(.success(()))
                NotificationCenter.default.post(name: .domainsServiceDomainsRefreshed, object: nil)
            }, on: .main)
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
    private func sortedSuggestions(_ suggestions: [RemoteDomainSuggestion], query: String) -> [RemoteDomainSuggestion] {
        let normalizedQuery = query.lowercased().replacingMatches(of: " ", with: "")

        var filteredSuggestions = suggestions
        if let matchedSuggestionIndex = suggestions.firstIndex(where: { $0.subdomain == query || $0.subdomain == normalizedQuery }) {
            let matchedSuggestion = filteredSuggestions.remove(at: matchedSuggestionIndex)
            filteredSuggestions.insert(matchedSuggestion, at: 0)
        }

        return filteredSuggestions
    }

    private func mergeDomains(_ domains: [Domain], forSite siteID: Int, in context: NSManagedObjectContext) {
        let remoteDomains = domains
        let localDomains = domainsForSite(siteID, in: context)

        let remoteDomainNames = Set(remoteDomains.map({ $0.domainName }))
        let localDomainNames = Set(localDomains.map({ $0.domainName }))

        let removedDomainNames = localDomainNames.subtracting(remoteDomainNames)
        removeDomains(removedDomainNames, fromSite: siteID, in: context)

        // Let's try to only update objects that have changed
        let remoteChanges = remoteDomains.filter {
            return !localDomains.contains($0)
        }

        for remoteDomain in remoteChanges {
            if let existingDomain = managedDomainWithName(remoteDomain.domainName, forSite: siteID, in: context),
               let blog = blogForSiteID(siteID, in: context) {
                existingDomain.updateWith(remoteDomain, blog: blog)
                DDLogDebug("Updated domain \(existingDomain)")
            } else {
                create(remoteDomain, forSite: siteID, in: context)
            }
        }
    }

    private func blogForSiteID(_ siteID: Int, in context: NSManagedObjectContext) -> Blog? {
        guard let blog = try? Blog.lookup(withID: siteID, in: context) else {
            let error = "Tried to obtain a Blog for a non-existing site (ID: \(siteID))"
            assertionFailure(error)
            DDLogError(error)
            return nil
        }

        return blog
    }

    private func managedDomainWithName(_ domainName: String, forSite siteID: Int, in context: NSManagedObjectContext) -> ManagedDomain? {
        guard let blog = blogForSiteID(siteID, in: context) else { return nil }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDomain.entityName())
        request.predicate = NSPredicate(format: "%K = %@ AND %K = %@", ManagedDomain.Relationships.blog, blog, ManagedDomain.Attributes.domainName, domainName)
        request.fetchLimit = 1
        let results = (try? context.fetch(request) as? [ManagedDomain]) ?? []
        return results.first
    }

    func create(_ domain: Domain, forSite siteID: Int) {
        coreDataStack.performAndSave { context in
            self.create(domain, forSite: siteID, in: context)
        }
    }

    private func create(_ domain: Domain, forSite siteID: Int, in context: NSManagedObjectContext) {
        guard let blog = blogForSiteID(siteID, in: context) else { return }

        let managedDomain = NSEntityDescription.insertNewObject(forEntityName: ManagedDomain.entityName(), into: context) as! ManagedDomain
        managedDomain.updateWith(domain, blog: blog)
        DDLogDebug("Created domain \(managedDomain)")
    }

    private func domainsForSite(_ siteID: Int, in context: NSManagedObjectContext) -> [Domain] {
        guard let blog = blogForSiteID(siteID, in: context) else { return [] }

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

    private func removeDomains(_ domainNames: Set<String>, fromSite siteID: Int, in context: NSManagedObjectContext) {
        guard let blog = blogForSiteID(siteID, in: context) else { return }

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
    init?(coreDataStack: CoreDataStack, account: WPAccount) {
        guard let wordPressComRestApi = account.wordPressComRestApi else { return nil }
        self.init(coreDataStack: coreDataStack, remote: DomainsServiceRemote(wordPressComRestApi: wordPressComRestApi))
    }
}

extension NSNotification.Name {
    /// Sent when domains are refreshed by ``DomainsService``
    static let domainsServiceDomainsRefreshed = NSNotification.Name("DomainsServiceDomainsRefreshed")
}
