import Foundation
import WordPressKit

extension ReaderTopicService {
    public func fetchInterests(success: @escaping([RemoteReaderInterest]) -> Void,
                               failure: @escaping(Error) -> Void) {
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())

        service.fetchInterests({ (interests) in
            success(interests)
        }) { (error) in
            failure(error)
        }
    }

    private func apiRequest() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let defaultAccount = accountService.defaultWordPressComAccount()

        if let api = defaultAccount?.wordPressComRestApi, api.hasCredentials() {
            return api
        }

        return WordPressComRestApi.defaultApi(oAuthToken: nil,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
    }
}
