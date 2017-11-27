import UIKit


/// Encapsulates logic to present a Helpshift window (for FAQs, a single FAQ,
/// or a conversation) from anywhere in the app.
///
@objc class HelpshiftPresenter: NSObject {

    /// set the source of the presenter for tagging in Helpshift
    @objc var sourceTag: SupportSourceTag?

    /// any additional options to pass along to helpshift
    @objc var optionsDictionary: [AnyHashable: Any]?

    /// Presents a Helpshift window displaying a specific FAQ.
    ///
    /// - Parameters:
    ///   - faqID: The 'publish ID' of the FAQ to display.
    ///   - viewController: The view controller from which to present the Helpshift window.
    ///   - completion: Optional block to be called when the window is presented.
    @objc func presentHelpshiftWindowForFAQ(_ faqID: String, fromViewController viewController: UIViewController, completion: (() -> Void)?) {
        prepareToDisplayHelpshiftWindow(false) {
            HelpshiftSupport.showSingleFAQ(faqID, with: viewController, with: self.helpshiftConfig())
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
    @objc func presentHelpshiftConversationWindowFromViewController(_ viewController: UIViewController, refreshUserDetails: Bool, completion: (() -> Void)?) {
        prepareToDisplayHelpshiftWindow(refreshUserDetails) {
            HelpshiftSupport.showConversation(viewController, with: self.helpshiftConfig())
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
    @objc func presentHelpshiftFAQWindowFromViewController(_ viewController: UIViewController, refreshUserDetails: Bool, completion: (() -> Void)?) {
        prepareToDisplayHelpshiftWindow(refreshUserDetails) {
            HelpshiftSupport.showFAQs(viewController, with: self.helpshiftConfig())
            completion?()
        }
    }

    fileprivate func updateHelpshiftUserDetailsWithAccount(_ account: WPAccount) {
        HelpshiftSupport.setUserIdentifier(account.userID.stringValue)
        HelpshiftCore.setName(account.displayName, andEmail: account.email)
    }

    fileprivate func prepareToDisplayHelpshiftWindow(_ refreshUserDetails: Bool, completion: @escaping () -> Void) {
        UserDefaults.standard.set(true, forKey: UserDefaultsHelpshiftWasUsed)

        PushNotificationsManager.shared.registerForRemoteNotifications()
        InteractiveNotificationsManager.shared.requestAuthorization()

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

    fileprivate func helpshiftConfig() -> HelpshiftAPIConfig {
        let tags: [String]
        if let sourceTag = sourceTag {
            tags = [String(sourceTag.rawValue)]
        } else {
            tags = []
        }

        var metaData = HelpshiftUtils.helpshiftMetadata(withTags: tags) as [AnyHashable: Any]
        if let customOptions = optionsDictionary {
            customOptions.forEach {
                metaData[$0] = $1
            }
        }

        let config: [AnyHashable: Any] = [HelpshiftSupportCustomMetadataKey: metaData]

        let builder = HelpshiftAPIConfigBuilder()
        builder.extraConfig = config
        builder.showSearchOnNewConversation = true

        return builder.build()
    }
}
