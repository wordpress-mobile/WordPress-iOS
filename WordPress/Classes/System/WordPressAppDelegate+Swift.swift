import Foundation

// MARK: - Local Notification Helpers

extension WordPressAppDelegate {

    @objc func addNotificationObservers() {
        let nc = NotificationCenter.default

        nc.addObserver(self,
                       selector: #selector(handleDefaultAccountChangedNotification(_:)),
                       name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged,
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(handleLowMemoryWarningNotification(_:)),
                       name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(handleUIContentSizeCategoryDidChangeNotification(_:)),
                       name: NSNotification.Name.UIContentSizeCategoryDidChange,
                       object: nil)
    }

    @objc fileprivate func handleDefaultAccountChangedNotification(_ notification: NSNotification) {
        // If the notification object is not nil, then it's a login
        if notification.object != nil {
            setupShareExtensionToken()
        } else {
            trackLogoutIfNeeded()
            removeTodayWidgetConfiguration()
            removeShareExtensionConfiguration()
            showWelcomeScreenIfNeeded(animated: false)
        }

        toggleExtraDebuggingIfNeeded()

        WPAnalytics.track(.defaultAccountChanged)
    }

    @objc fileprivate func handleLowMemoryWarningNotification(_ notification: NSNotification) {
        WPAnalytics.track(.lowMemoryWarning)
    }

    @objc fileprivate func handleUIContentSizeCategoryDidChangeNotification(_ notification: NSNotification) {
        customizeAppearanceForTextElements()
    }
}

// MARK: - Extensions

extension WordPressAppDelegate {

    @objc func setupWordPressExtensions() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        accountService.setupAppExtensionsWithDefaultAccount()

        let maxImagesize = MediaSettings().maxImageSizeSetting
        ShareExtensionService.configureShareExtensionMaximumMediaDimension(maxImagesize)
    }

    // MARK: - Today Extension

    @objc func removeTodayWidgetConfiguration() {
        TodayExtensionService().removeTodayWidgetConfiguration()
    }

    // MARK: - Share Extension

    @objc func setupShareExtensionToken() {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        if let account = accountService.defaultWordPressComAccount() {
            ShareExtensionService.configureShareExtensionToken(account.authToken)
            ShareExtensionService.configureShareExtensionUsername(account.username)
        }
    }

    @objc func removeShareExtensionConfiguration() {
        ShareExtensionService.removeShareExtensionConfiguration()
    }
}
