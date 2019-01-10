import WordPressKit

// MARK: - SiteAddressService

typealias SiteAddressServiceCompletion = (Result<[DomainSuggestion]>) -> Void

protocol SiteAddressService {
    func addresses(for query: String, completion: @escaping SiteAddressServiceCompletion)
}

// MARK: - MockSiteAddressService

final class MockSiteAddressService: SiteAddressService {
    func addresses(for query: String, completion: @escaping SiteAddressServiceCompletion) {
        let result = Result.success(mockAddresses())
        completion(result)
    }

    private func mockAddresses() -> [DomainSuggestion] {
        return [ DomainSuggestion(name: "ravenclaw.wordpress.com"),
                 DomainSuggestion(name: "ravenclaw.com"),
                 DomainSuggestion(name: "team.ravenclaw.com")]
    }
}

private extension DomainSuggestion {
    init(name: String) {
        try! self.init(json: ["domain_name": name as AnyObject])
    }
}

// MARK: - DomainsServiceAdapter

final class DomainsServiceAdapter: LocalCoreDataService, SiteAddressService {

    // MARK: Properties

    /// The existing service for retrieving DomainSuggestions
    private let domainsService: DomainsService

    // MARK: LocalCoreDataService

    override init(managedObjectContext context: NSManagedObjectContext) {
        let accountService = AccountService(managedObjectContext: context)

        let api: WordPressComRestApi
        if let wpcomApi = accountService.defaultWordPressComAccount()?.wordPressComRestApi {
            api = wpcomApi
        } else {
            api = WordPressComRestApi(userAgent: WPUserAgent.wordPress())
        }
        let remoteService = DomainsServiceRemote(wordPressComRestApi: api)

        self.domainsService = DomainsService(managedObjectContext: context, remote: remoteService)

        super.init(managedObjectContext: context)
    }

    // MARK: SiteAddressService

    func addresses(for query: String, completion: @escaping SiteAddressServiceCompletion) {
        domainsService.getDomainSuggestions(base: query,
                                            success: { domainSuggestions in
                                                completion(Result.success(domainSuggestions))
        },
                                            failure: { error in
                                                completion(Result.error(error))
        })
    }
}
