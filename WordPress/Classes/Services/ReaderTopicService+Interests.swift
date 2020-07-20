import Foundation
import WordPressKit

// MARK: - ReaderInterestsService

/// Protocol representing a service that retrieves a list of interests the user can follow
protocol ReaderInterestsService: AnyObject {
    func fetchInterests(success: @escaping ([RemoteReaderInterest]) -> Void,
                        failure: @escaping (Error) -> Void)
}

// MARK: - Select Interests
extension ReaderTopicService: ReaderInterestsService {
    public func fetchInterests(success: @escaping ([RemoteReaderInterest]) -> Void,
                               failure: @escaping (Error) -> Void) {
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())

        service.fetchInterests({ (interests) in
            success(interests)
        }) { (error) in
            failure(error)
        }
    }


    /// Creates a new WP.com API instances that allows us to specify the LocaleKeyV2
    private func apiRequest() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
    }
}
