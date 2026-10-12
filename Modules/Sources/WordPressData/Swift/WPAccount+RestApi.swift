import WordPressKit
import CoreData
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
            userAgent: WPUserAgent.wordPress(),
            localeKey: WordPressComRestApi.LocaleKeyDefault
        )

        let accountID = TaggedManagedObjectID(self)
        let context = managedObjectContext
        wpAssert(context != nil)

        api.setInvalidTokenHandler {
            // We use a static function here because it's not safe to access `self` in this closure.
            // The `WPAccount` instance can be bound to any context object. There is no guarantee that the thread
            // from which this closure is called is the same as the one in the context object.
            //
            // `WordPressComRestApi` calls this handler on the main queue. Waiting for the context blocks the main
            // queue, where sign-in stores replacement tokens, so a replacement cannot be written between the
            // comparison and the clear.
            context?.performAndWait {
                WPAccount.handleInvalidToken(accountID: accountID, rejectedToken: authToken, context: context)
            }
        }

        return api
    }

    /// Returns an instance of the WPCOM REST API suitable for v2 endpoints.
    /// If the user is not authenticated, this will be anonymous.
    ///
    public var wordPressComRestV2Api: WordPressComRestApi {
        let token = authToken
        let userAgent = WPUserAgent.wordPress()
        let localeKey = WordPressComRestApi.LocaleKeyV2

        return WordPressComRestApi.defaultApi(oAuthToken: token, userAgent: userAgent, localeKey: localeKey)
    }

    /// A `WordPressRestComApi` object if a default account exists in the giveng `NSManagedObjectContext` and is a WordPress.com account.
    /// Otherwise, it returns `nil`
    public static func defaultWordPressComAccountRestAPI(in context: NSManagedObjectContext) throws -> WordPressComRestApi? {
        let account = try WPAccount.lookupDefaultWordPressComAccount(in: context)
        return account?.wordPressComRestApi
    }

    /// Clears the account's token after the server rejected it, and asks for the WordPress.com sign-in.
    ///
    /// This does not post `wpAccountDefaultWordPressComAccountChanged`: the account and its sites still exist, and
    /// observers treat that notification without an object as a logout.
    static func handleInvalidToken(
        accountID: TaggedManagedObjectID<WPAccount>,
        rejectedToken: String,
        context: NSManagedObjectContext?
    ) {
        guard let account = try? context?.existingObject(with: accountID) else {
            return
        }

        // Storing a new token does not cancel requests made with the previous one. A late rejection of the
        // previous token must not erase its replacement. This instance may still cache the previous token, if the
        // replacement was stored through another context, so make it read the replacement next time.
        guard account.authTokenInKeychain == rejectedToken else {
            WPLogInfo("Ignoring a rejection of a WordPress.com token that is no longer current")
            account.discardCachedToken()
            return
        }

        account.authToken = nil

        NotificationCenter.default.post(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account
        )
    }
}

public extension Foundation.Notification.Name {

    /// This notification is posted when a `WPAccount` instance's `authToken` is found to be invalid.
    /// The object property of the posted notification is an `TaggedManagedObjectID<WPAccount>` instance.
    static let wpAccountRequiresShowingSigninForWPComFixingAuthToken = Foundation.Notification.Name("WPAccount.WPComAuthTokenNeedsFixing")

    static let wpAccountDefaultWordPressComAccountChanged = Foundation.Notification.Name("WPAccount.DefaultWordPressComAccountChangedNotification")
}

// For Objective-C compatibility
@objc public extension NSNotification {

    @available(*, unavailable)
    static let wpAccountDefaultWordPressComAccountChangedNotificationName = Foundation.Notification.Name.wpAccountDefaultWordPressComAccountChanged
}
