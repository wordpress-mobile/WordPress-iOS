import Foundation
import WordPressKit

extension WordPressComRestApi {
    @objc public static func defaultApi(oAuthToken: String? = nil,
                                        userAgent: String? = nil,
                                        localeKey: String = WordPressComRestApi.LocaleKeyDefault) -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: oAuthToken,
                                   userAgent: userAgent,
                                   localeKey: localeKey,
                                   baseUrlString: Environment.current.wordPressComApiBase)
    }


    /// Returns the default API the default WP.com account using the given context
    @objc public static func defaultApi(in context: NSManagedObjectContext,
                                        userAgent: String? = WPUserAgent.wordPress(),
                                        localeKey: String = WordPressComRestApi.LocaleKeyDefault) -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: context)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress())
    }
}
