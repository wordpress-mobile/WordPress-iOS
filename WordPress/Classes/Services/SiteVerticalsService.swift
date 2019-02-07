
// MARK: - SiteVerticalsService

/// Abstracts retrieval of site verticals.
///
protocol SiteVerticalsService {
    func retrieveVerticals(request: SiteVerticalsRequest, completion: @escaping SiteVerticalsServiceCompletion)
}

// MARK: - MockSiteVerticalsService

/// Mock implementation of the SiteVerticalsService
///
final class MockSiteVerticalsService: SiteVerticalsService {
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

    func retrieveVerticals(request: SiteVerticalsRequest, completion: @escaping SiteVerticalsServiceCompletion) {
        remoteService.retrieveVerticals(request: request) { result in
            completion(result)
        }
    }
}
