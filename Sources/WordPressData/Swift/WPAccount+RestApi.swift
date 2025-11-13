import WordPressKit
import WordPressShared

extension WPAccount {

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

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .wpAccountDefaultWordPressComAccountChanged,
                    object: nil
                )
            }
        }
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
