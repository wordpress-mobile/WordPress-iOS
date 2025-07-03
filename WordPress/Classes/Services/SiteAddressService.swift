import WordPressData
import WordPressKit
import WordPressShared

// MARK: - SiteAddressService

struct SiteAddressServiceResult {
    let domainSuggestions: [DomainSuggestion]
    let invalidQuery: Bool

    init(domainSuggestions: [DomainSuggestion] = [], invalidQuery: Bool = false) {
        self.domainSuggestions = domainSuggestions
        self.invalidQuery = invalidQuery
    }
}

typealias SiteAddressServiceCompletion = (Result<SiteAddressServiceResult, Error>) -> Void

protocol SiteAddressService {
    func addresses(for query: String, type: DomainsServiceRemote.DomainSuggestionType, completion: @escaping SiteAddressServiceCompletion)
}

private extension DomainSuggestion {
    init(name: String) {
        try! self.init(json: ["domain_name": name as AnyObject])
    }
}

// MARK: - DomainsServiceAdapter

final class DomainsServiceAdapter: SiteAddressService {

    // MARK: Properties

    /**
     Corresponds to:

     Error Domain=WordPressKit.WordPressComRestApiError Code=7 "No available domains for that search." UserInfo={NSLocalizedDescription=No available domains for that search., WordPressComRestApiErrorCodeKey=empty_results, WordPressComRestApiErrorMessageKey=No available domains for that search.}
     */
    private static let emptyResultsErrorCode = 7

    /// Overrides the default quantity in the server request,
    private let domainRequestQuantity = 20

    /// The existing service for retrieving DomainSuggestions
    private let domainsService: DomainsService

    // MARK: LocalCoreDataService

    @objc convenience init(coreDataStack: CoreDataStack) {
        let api: WordPressComRestApi = coreDataStack.performQuery({
                (try? WPAccount.lookupDefaultWordPressComAccount(in: $0))?.wordPressComRestApi
            }) ?? WordPressComRestApi.defaultApi(userAgent: WPUserAgent.wordPress())

        self.init(coreDataStack: coreDataStack, api: api)
    }

    // Used to help with testing
    init(coreDataStack: CoreDataStack, api: WordPressComRestApi) {
        let remoteService = DomainsServiceRemote(wordPressComRestApi: api)
        self.domainsService = DomainsService(coreDataStack: coreDataStack, remote: remoteService)
    }

    @objc func refreshDomains(siteID: Int, completion: @escaping (Bool) -> Void) {
        domainsService.refreshDomains(siteID: siteID) { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }

    // MARK: SiteAddressService

    func addresses(for query: String, type: DomainsServiceRemote.DomainSuggestionType, completion: @escaping SiteAddressServiceCompletion) {
        domainsService.getDomainSuggestions(
            query: query,
            quantity: domainRequestQuantity,
            domainSuggestionType: type,
            success: { suggestions in
                completion(Result.success(.init(domainSuggestions: suggestions)))
            },
            failure: { error in
                if (error as NSError).code == DomainsServiceAdapter.emptyResultsErrorCode {
                    completion(Result.success(SiteAddressServiceResult()))
                    return
                }
                if (error as NSError).code == WordPressComRestApiErrorCode.invalidQuery.rawValue {
                    completion(Result.success(SiteAddressServiceResult(invalidQuery: true)))
                    return
                }

                completion(Result.failure(error))
            }
        )
    }
}
