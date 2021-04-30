import AutomatticTracks

// MARK: - SiteVerticalsService

/// Advises the caller of results related to requests for a specific site vertical.
///
/// - success: the site vertical request succeeded with the accompanying result.
/// - failure: the site vertical request failed due to the accompanying error.
///
public enum SiteVerticalRequestResult {
    case success(SiteVertical)
    case failure(SiteVerticalsError)
}

typealias SiteVerticalRequestCompletion = (SiteVerticalRequestResult) -> ()

/// Abstracts retrieval of site verticals.
///
protocol SiteVerticalsService {
    func retrieveVertical(named verticalName: String, completion: @escaping SiteVerticalRequestCompletion)
    func retrieveVerticals(request: SiteVerticalsRequest, completion: @escaping SiteVerticalsServiceCompletion)
}

// MARK: - MockSiteVerticalsService

/// Mock implementation of the SiteVerticalsService
///
final class MockSiteVerticalsService: SiteVerticalsService {
    func retrieveVertical(named verticalName: String, completion: @escaping SiteVerticalRequestCompletion) {
        let vertical = SiteVertical(identifier: "SV 1", title: "Vertical 1", isNew: false)
        completion(.success(vertical))
    }

    func retrieveVerticals(request: SiteVerticalsRequest, completion: @escaping SiteVerticalsServiceCompletion) {
        let result = SiteVerticalsResult.success(mockVerticals())
        completion(result)
    }

    private func mockVerticals() -> [SiteVertical] {
        return [ SiteVertical(identifier: "SV 1", title: "Vertical 1", isNew: false),
                 SiteVertical(identifier: "SV 2", title: "Vertical 2", isNew: false),
                 SiteVertical(identifier: "SV 3", title: "Landscap", isNew: true) ]
    }
}

// MARK: - SiteCreationVerticalsService

/// Retrieves candidate Site Verticals used to create a new site.
///
final class SiteCreationVerticalsService: LocalCoreDataService, SiteVerticalsService {

    // MARK: Properties

    /// A service for interacting with WordPress accounts.
    private let accountService: AccountService

    /// A facade for WPCOM services.
    private let remoteService: WordPressComServiceRemote

    // MARK: LocalCoreDataService

    override init(managedObjectContext context: NSManagedObjectContext) {
        self.accountService = AccountService(managedObjectContext: context)

        let api: WordPressComRestApi
        if let account = accountService.defaultWordPressComAccount() {
            api = account.wordPressComRestV2Api
        } else {
            api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)
        }
        self.remoteService = WordPressComServiceRemote(wordPressComRestApi: api)

        super.init(managedObjectContext: context)
    }

    // MARK: SiteVerticalsService

    func retrieveVertical(named verticalName: String, completion: @escaping SiteVerticalRequestCompletion) {
        let request = SiteVerticalsRequest(search: verticalName, limit: 1)

        remoteService.retrieveVerticals(request: request) { result in
            switch result {
            case .success(let verticals):
                guard let vertical = verticals.first else {
                    WordPressAppDelegate.crashLogging?.logMessage("The verticals service should always return at least 1 match for the precise term queried.", level: .error)
                    completion(.failure(.serviceFailure))
                    return
                }

                completion(.success(vertical))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func retrieveVerticals(request: SiteVerticalsRequest, completion: @escaping SiteVerticalsServiceCompletion) {
        remoteService.retrieveVerticals(request: request) { result in
            completion(result)
        }
    }
}
