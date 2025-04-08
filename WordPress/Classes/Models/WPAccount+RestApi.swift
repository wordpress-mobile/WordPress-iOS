import WordPressKit
import WordPressShared

extension WPAccount {

    /// A `WordPressRestComApi` object if the account is a WordPress.com account. Otherwise, `nil`.
    ///
    /// Warning: The getter has various side effects when there is no previous value set, including triggering the signup flow!
    ///
    /// This used to be defined in the Objective-C layer, but we moved it here in a Swift extension in an attempt to decouple the model code from it.
    /// This was done in the context of https://github.com/wordpress-mobile/WordPress-iOS/pull/24165 .
    @objc public var wordPressComRestApi: WordPressComRestApi? {
        if let api = _private_wordPressComRestApi {
            return api
        }

        guard let authToken, !authToken.isEmpty else {
            NotificationCenter.default.post(
                name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
                object: self
            )
            return nil
        }

        let api = makeWordPressComRestApi(authToken: authToken)
        self._private_wordPressComRestApi = api
        return api
    }

    private func makeWordPressComRestApi(authToken: String) -> WordPressComRestApi {
        let api = WordPressComRestApi.defaultApi(
            oAuthToken: authToken,
            userAgent: WPUserAgent.defaultUserAgent(),
            localeKey: WordPressComRestApi.LocaleKeyDefault
        )

        let accountID = TaggedManagedObjectID(self)
        let context = managedObjectContext
        wpAssert(context != nil)

        api.setInvalidTokenHandler {
            // We use a static function here because it's not safe to access `self` in this closure.
            // The `WPAccount` instance can be bound to any context object. There is no guarantee that the thread
            // from which this closure is called is the same as the one in the context object.
            context?.perform {
                WPAccount.handleInvalidToken(accountID: accountID, context: context)
            }
        }

        return api
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

    static func handleInvalidToken(accountID: TaggedManagedObjectID<WPAccount>, context: NSManagedObjectContext?) {
        let account = try? context?.existingObject(with: accountID)
        account?.authToken = nil

        NotificationCenter.default.post(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account
        )

        if account?.isDefaultWordPressComAccount == true {
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
    }
}

extension Foundation.Notification.Name {

    /// This notification is posted when a `WPAccount` instance's `authToken` is found to be invalid.
    /// The object property of the posted notification is an `TaggedManagedObjectID<WPAccount>` instance.
    static let wpAccountRequiresShowingSigninForWPComFixingAuthToken = Foundation.Notification.Name("WPAccount.WPComAuthTokenNeedsFixing")
}
