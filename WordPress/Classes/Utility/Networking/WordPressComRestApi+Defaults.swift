import Foundation
import WordPressKit

extension WordPressComRestApi {
    @objc public static func defaultApi(oAuthToken: String? = nil,
                                        userAgent: String? = nil,
                                        localeKey: String = WordPressComRestApi.LocaleKeyDefault) -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: oAuthToken,
                                   userAgent: userAgent,
                                   localeKey: localeKey,
                                   baseURL: Environment.current.wordPressComApiBase)
    }

    /// Returns the default API the default WP.com account using the given context
    @objc public static func defaultApi(in context: NSManagedObjectContext,
                                        userAgent: String? = WPUserAgent.wordPress(),
                                        localeKey: String = WordPressComRestApi.LocaleKeyDefault) -> WordPressComRestApi {

        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: userAgent,
                                              localeKey: localeKey)
    }

    @objc public static func defaultV2Api(authToken: String? = nil) -> WordPressComRestApi {
        let userAgent = WPUserAgent.wordPress()
        let localeKey = WordPressComRestApi.LocaleKeyV2
        return WordPressComRestApi.defaultApi(oAuthToken: authToken,
                                              userAgent: userAgent,
                                              localeKey: localeKey)
    }

    @objc public static func defaultV2Api(in context: NSManagedObjectContext) -> WordPressComRestApi {
        return WordPressComRestApi.defaultApi(in: context,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
    }
}
