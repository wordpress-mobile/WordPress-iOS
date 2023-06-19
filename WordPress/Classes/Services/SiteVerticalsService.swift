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

// MARK: - SiteCreationVerticalsService

/// Retrieves candidate Site Verticals used to create a new site.
///
final class SiteCreationVerticalsService: SiteVerticalsService {

    // MARK: Properties

    /// A facade for WPCOM services.
    private let remoteService: WordPressComServiceRemote

    init(coreDataStack: CoreDataStack) {
        let api = coreDataStack.performQuery({ context in
            try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.wordPressComRestV2Api
        }) ?? WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)
        self.remoteService = WordPressComServiceRemote(wordPressComRestApi: api)
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
