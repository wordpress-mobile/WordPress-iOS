import WordPressKit
import WordPressShared

extension WPAccount {

    /// A `WordPressRestComApi` object if the account is a WordPress.com account. Otherwise, `nil`.
    ///
    /// Warning: The getter has various side effects when there is no previous value set, including triggering the signup flow!
    ///
    /// This used to be defined in the Objective-C layer, but we moved it here in a Swift extension in an attempt to decouple the model code from it.
    /// This was done in the context of https://github.com/wordpress-mobile/WordPress-iOS/pull/24165 .
    @objc var wordPressComRestApi: WordPressComRestApi? {
        get {
            guard let api = objc_getAssociatedObject(self, &apiAssociatedKey) as? WordPressComRestApi else {
                guard authToken.isEmpty else {
                    let api = WordPressComRestApi.defaultApi(
                        oAuthToken: authToken,
                        userAgent: WPUserAgent.defaultUserAgent(),
                        localeKey: WordPressComRestApi.LocaleKeyDefault
                    )

                    api.setInvalidTokenHandler { [weak self] in
                        guard let self else { return }

                        self.authToken = nil
                        WordPressAuthenticationManager.showSigninForWPComFixingAuthToken()

                        guard self.isDefaultWordPressComAccount else { return }

                        // At the time of writing, there is an implicit assumption on what the object parameter value means.
                        // For example, the WordPressAppDelegate.handleDefaultAccountChangedNotification(_:) subscriber inspects the object parameter to decide whether the notification was sent as a result of a login.
                        // If the object is non-nil, then the method considers the source a login.
                        //
                        // The code path in which we are is that of an invalid token, and that's neither a login nor a logout, it's more appropriate to consider it a logout.
                        // That's because if the token is invalid the app will soon received errors from the API and it's therefore better to force the user to login again.
                        NotificationCenter.default.post(
                            name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged,
                            object: nil
                        )
                    }

                    return api
                }

                DispatchQueue.main.async {
                    WordPressAuthenticationManager.showSigninForWPComFixingAuthToken()
                }
                return nil
            }
            return api
        }
        set(api) {
            objc_setAssociatedObject(self, &apiAssociatedKey, api, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

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

private var apiAssociatedKey: UInt8 = 0
