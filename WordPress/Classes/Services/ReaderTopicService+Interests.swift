import Foundation
import WordPressKit

// MARK: - ReaderInterestsService

/// Protocol representing a service that retrieves a list of interests stored remotely
protocol ReaderInterestsService: AnyObject {
    /// Fetches a large list of interests from the server
    /// - Parameters:
    ///   - success: Called upon successful completion and parsing, provides an array of `RemoteReaderInterest` objects
    ///   - failure: Called upon network failure, or parsing errors, provides an Error object
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
