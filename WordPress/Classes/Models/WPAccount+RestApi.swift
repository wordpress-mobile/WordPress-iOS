import WordPressKit
import WordPressShared

extension WPAccount {
    /// Returns an instance of the WPCOM REST API suitable for v2 endpoints.
    /// If the user is not authenticated, this will be anonymous.
    ///
    var wordPressComRestV2Api: WordPressComRestApi {
        let token = authToken
        let userAgent = WPUserAgent.wordPress()
        let localeKey = WordPressComRestApi.LocaleKeyV2

        return WordPressComRestApi.defaultApi(oAuthToken: token, userAgent: userAgent, localeKey: localeKey)
    }

    /// A `WordPressRestComApi` object if a default account exists in the giveng `NSManagedObjectContext` and is a WordPress.com account.
    /// Otherwise, it returns `nil`
    static func defaultWordPressComAccountRestAPI(in context: NSManagedObjectContext) throws -> WordPressComRestApi? {
        let account = try WPAccount.lookupDefaultWordPressComAccount(in: context)
        return account?.wordPressComRestApi
    }
}
