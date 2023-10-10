import Foundation
import WordPressKit

extension WordPressComRestApi {
    @objc public static func defaultApi(oAuthToken: String? = nil,
                                        userAgent: String? = nil,
                                        localeKey: String = WordPressComRestApi.LocaleKeyDefault) -> WordPressComRestApi {
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        let baseURLString: String
        if isRunningTests {
            // This is the same value as the default .wordPressComApiBase
            // but hardcoded so that we don't init an Environment and trigger a CoreDataStack setup in the tests, which would in turn result in multiple model loads and possible runtime inconsistencies
            baseURLString = "https://public-api.wordpress.com/"
        } else {
            baseURLString = Environment.current.wordPressComApiBase
        }
        return WordPressComRestApi(oAuthToken: oAuthToken,
                                   userAgent: userAgent,
                                   localeKey: localeKey,
                                   baseUrlString: baseURLString)
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
