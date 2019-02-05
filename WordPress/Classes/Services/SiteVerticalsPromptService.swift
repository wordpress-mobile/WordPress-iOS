
import Foundation

// MARK: - SiteVerticalsPromptService

/// Abstracts retrieval of prompt values for Site Creation : Verticals search & selection.
///
protocol SiteVerticalsPromptService {
    func retrieveVerticalsPrompt(request: SiteVerticalsPromptRequest, completion: @escaping SiteVerticalsPromptServiceCompletion)
}

// MARK: - MockSiteVerticalsPromptService

/// Mock implementation of the prompt service
///
final class MockSiteVerticalsPromptService: SiteVerticalsPromptService {
    func retrieveVerticalsPrompt(request: SiteVerticalsPromptRequest, completion: @escaping
        SiteVerticalsPromptServiceCompletion) {

        let mockPrompt = SiteVerticalsPrompt(title: "Faux title", subtitle: "Faux subtitle", hint: "Faux placeholder")
        completion(mockPrompt)
    }
}

// MARK: - SiteCreationVerticalsPromptService

/// Retrieves localized user-facing prompts for searching Verticals during Site Creation.
///
final class SiteCreationVerticalsPromptService: LocalCoreDataService, SiteVerticalsPromptService {

    // MARK: Properties

    /// A service for interacting with WordPress accounts.
    private let accountService: AccountService

    /// A facade for WPCOM services.
    private let remoteService: WordPressComServiceRemote

    // MARK: LocalCoreDataService

    override init(managedObjectContext context: NSManagedObjectContext) {
        self.accountService = AccountService(managedObjectContext: context)

        let userAgent = WPUserAgent.wordPress()
        let localeKey = WordPressComRestApi.LocaleKeyV2

        let api: WordPressComRestApi
        if let account = accountService.defaultWordPressComAccount(), let token = account.authToken {
            api = WordPressComRestApi(oAuthToken: token, userAgent: userAgent, localeKey: localeKey)
        } else {
            api = WordPressComRestApi(userAgent: userAgent, localeKey: localeKey)
        }

        self.remoteService = WordPressComServiceRemote(wordPressComRestApi: api)

        super.init(managedObjectContext: context)
    }

    // MARK: SiteVerticalsPromptService

    func retrieveVerticalsPrompt(request: SiteVerticalsPromptRequest, completion: @escaping SiteVerticalsPromptServiceCompletion) {
        remoteService.retrieveVerticalsPrompt(request: request, completion: completion)
    }
}
