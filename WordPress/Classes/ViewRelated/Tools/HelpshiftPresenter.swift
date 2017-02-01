import UIKit


/// Encapsulates logic to present a Helpshift window (for FAQs, a single FAQ,
/// or a conversation) from anywhere in the app.
///
@objc class HelpshiftPresenter: NSObject {
    // Passed into options when displaying a Helpshift window, so that users are presented
    // a list of possibly related FAQs with matching terms before posting a new conversation.
    fileprivate static let HelpshiftShowsSearchOnNewConversationKey = "showSearchOnNewConversation"


    /// set the source of the presenter for tagging in Helpshift
    var sourceTag: SupportSourceTag?

    /// Presents a Helpshift window displaying a specific FAQ.
    ///
    /// - Parameters:
    ///   - faqID: The 'publish ID' of the FAQ to display.
    ///   - viewController: The view controller from which to present the Helpshift window.
    ///   - completion: Optional block to be called when the window is presented.
    func presentHelpshiftWindowForFAQ(_ faqID: String, fromViewController viewController: UIViewController, completion: (() -> Void)?) {
        prepareToDisplayHelpshiftWindow(false) {
            HelpshiftSupport.showSingleFAQ(faqID, with: viewController, withOptions: self.optionsDictionary)
            completion?()
        }
    }

    /// Presents a Helpshift conversation window.
    ///
    /// - Parameters:
    ///   - viewController: The view controller from which to present the Helpshift window.
    ///   - refreshUserDetails: If `true`, refresh user ID, display name, and email emailAddress
    ///     from the WordPress.com REST API (if appropriate) before displaying the window.
    ///   - completion: Optional block to be called when the window is presented.
    func presentHelpshiftConversationWindowFromViewController(_ viewController: UIViewController, refreshUserDetails: Bool, completion: (() -> Void)?) {
        prepareToDisplayHelpshiftWindow(refreshUserDetails) {
            HelpshiftSupport.showConversation(viewController, withOptions: self.optionsDictionary)
            completion?()
        }
    }

    /// Presents a Helpshift window displaying the FAQs index.
    ///
    /// - Parameters:
    ///   - viewController: The view controller from which to present the Helpshift window.
    ///   - refreshUserDetails: If `true`, refresh user ID, display name, and email emailAddress
    ///     from the WordPress.com REST API (if appropriate) before displaying the window.
    ///   - completion: Optional block to be called when the window is presented.
    func presentHelpshiftFAQWindowFromViewController(_ viewController: UIViewController, refreshUserDetails: Bool, completion: (() -> Void)?) {
        prepareToDisplayHelpshiftWindow(refreshUserDetails) {
            HelpshiftSupport.showFAQs(viewController, withOptions: self.optionsDictionary)
            completion?()
        }
    }

    fileprivate func updateHelpshiftUserDetailsWithAccount(_ account: WPAccount) {
        HelpshiftSupport.setUserIdentifier(account.userID.stringValue)
        HelpshiftCore.setName(account.displayName, andEmail: account.email)
    }

    fileprivate func prepareToDisplayHelpshiftWindow(_ refreshUserDetails: Bool, completion: @escaping () -> Void) {
        UserDefaults.standard.set(true, forKey: UserDefaultsHelpshiftWasUsed)

        PushNotificationsManager.sharedInstance.registerForRemoteNotifications()
        InteractiveNotificationsManager.sharedInstance.requestAuthorization()

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        guard let defaultAccount = accountService.defaultWordPressComAccount() else {
            completion()
            return
        }

        guard refreshUserDetails else {
            updateHelpshiftUserDetailsWithAccount(defaultAccount)
            completion()
            return
        }

        accountService.updateUserDetails(for: defaultAccount, success: {
            self.updateHelpshiftUserDetailsWithAccount(defaultAccount)
            completion()
            }, failure: { _ in
                completion()
        })
    }

    fileprivate var optionsDictionary: [AnyHashable: Any] {
        let tags: [String]
        if let sourceTag = sourceTag {
            tags = [String(sourceTag.rawValue)]
        } else {
            tags = []
        }
        let options: [AnyHashable: Any] = [HelpshiftSupportCustomMetadataKey: HelpshiftUtils.helpshiftMetadata(withTags: tags),
                HelpshiftPresenter.HelpshiftShowsSearchOnNewConversationKey: true]
        return options
    }
}
