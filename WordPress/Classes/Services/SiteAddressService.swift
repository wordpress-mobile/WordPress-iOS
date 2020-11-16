import WordPressKit

// MARK: - SiteAddressService

typealias SiteAddressServiceCompletion = (Result<[DomainSuggestion], Error>) -> Void

protocol SiteAddressService {
    func addresses(for query: String, segmentID: Int64, completion: @escaping SiteAddressServiceCompletion)
    func addresses(for query: String, completion: @escaping SiteAddressServiceCompletion)
}

// MARK: - MockSiteAddressService

final class MockSiteAddressService: SiteAddressService {
    func addresses(for query: String, segmentID: Int64, completion: @escaping SiteAddressServiceCompletion) {
        completion(.success(mockAddresses()))
    }

    func addresses(for query: String, completion: @escaping SiteAddressServiceCompletion) {
        completion(.success(mockAddresses()))
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

    /**
     Corresponds to:

     Error Domain=WordPressKit.WordPressComRestApiError Code=7 "No available domains for that search." UserInfo={NSLocalizedDescription=No available domains for that search., WordPressComRestApiErrorCodeKey=empty_results, WordPressComRestApiErrorMessageKey=No available domains for that search.}
     */
    private static let emptyResultsErrorCode = 7

    /// The existing service for retrieving DomainSuggestions
    private let domainsService: DomainsService

    // MARK: LocalCoreDataService

    override init(managedObjectContext context: NSManagedObjectContext) {
        let accountService = AccountService(managedObjectContext: context)

        let api: WordPressComRestApi
        if let wpcomApi = accountService.defaultWordPressComAccount()?.wordPressComRestApi {
            api = wpcomApi
        } else {
            api = WordPressComRestApi.defaultApi(userAgent: WPUserAgent.wordPress())
        }
        let remoteService = DomainsServiceRemote(wordPressComRestApi: api)

        self.domainsService = DomainsService(managedObjectContext: context, remote: remoteService)

        super.init(managedObjectContext: context)
    }

    // MARK: SiteAddressService

    func addresses(for query: String, segmentID: Int64, completion: @escaping SiteAddressServiceCompletion) {

        domainsService.getDomainSuggestions(base: query,
                                            segmentID: segmentID,
                                            success: { domainSuggestions in
                                                completion(Result.success(domainSuggestions))
        },
                                            failure: { error in
                                                if (error as NSError).code == DomainsServiceAdapter.emptyResultsErrorCode {
                                                    completion(Result.success([]))
                                                    return
                                                }

                                                completion(Result.failure(error))
        })
    }

    func addresses(for query: String, completion: @escaping SiteAddressServiceCompletion) {
        domainsService.getDomainSuggestions(base: query,
                                            domainSuggestionType: .onlyWordPressDotCom,
                                            success: { domainSuggestions in
                                                completion(Result.success(domainSuggestions))
        },
                                            failure: { error in
                                                if (error as NSError).code == DomainsServiceAdapter.emptyResultsErrorCode {
                                                    completion(Result.success([]))
                                                    return
                                                }

                                                completion(Result.failure(error))
        })
    }
}
