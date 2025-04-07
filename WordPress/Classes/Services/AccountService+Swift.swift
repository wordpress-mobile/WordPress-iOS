import Foundation
import WordPressShared
import ShareExtensionCore
import WebKit

extension AccountService {
    // MARK: - Current Account

    @objc public static let defaultDotcomAccountUUIDDefaultsKey = "AccountDefaultDotcomUUID"

    @objc public func setDefaultWordPressComAccount(_ account: WPAccount) {
        wpAssert(account.authToken?.isEmpty == false, "Account should have an authToken for WP.com")

        guard !account.isDefaultWordPressComAccount else {
            return
        }

        UserPersistentStoreFactory.instance().set(account.uuid, forKey: AccountService.defaultDotcomAccountUUIDDefaultsKey)

        let objectID = TaggedManagedObjectID(account)
        let notifyAccountChange = {
            let context = self.coreDataStack.mainContext
            let account = try? context.existingObject(with: objectID)
            NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: account)

            PushNotificationsManager.shared.setupRemoteNotifications()
        }

        if Thread.isMainThread {
            // This is meant to help with testing account observers.
            // Short version: dispatch_async and XCTest asynchronous helpers don't play nice with each other
            // Long version: see the comment in https://github.com/wordpress-mobile/WordPress-iOS/blob/2f9a2100ca69d8f455acec47a1bbd6cbc5084546/WordPress/WordPressTest/AccountServiceRxTests.swift#L7
            notifyAccountChange()
        } else {
            DispatchQueue.main.async(execute: notifyAccountChange)
        }
    }

    func removeDefaultWordPressComAccount() {
        wpAssert(Thread.isMainThread, "Must be called from main thread")

        PushNotificationsManager.shared.unregisterDeviceToken()

        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: coreDataStack.mainContext) else {
            return
        }

        let objectID = TaggedManagedObjectID(account)
        coreDataStack.performAndSave { context in
            do {
                let account = try context.existingObject(with: objectID)
                context.delete(account)
            } catch {
                wpAssertionFailure("account missing")
            }
        }

        // Clear WordPress.com cookies
        let cookieJars: [CookieJar] = [
            HTTPCookieStorage.shared,
            WKWebsiteDataStore.default().httpCookieStore
        ]

        for cookieJar in cookieJars {
            cookieJar.removeWordPressComCookies(completion: {})
        }

        URLCache.shared.removeAllCachedResponses()

        // Remove defaults
        UserPersistentStoreFactory.instance().removeObject(forKey: AccountService.defaultDotcomAccountUUIDDefaultsKey)

        WPAnalytics.refreshMetadata()
        NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)

        StatsCache.clearCaches()
    }

    // MARK: - App Extensions

    func setupAppExtensions() {
        let context = coreDataStack.mainContext
        context.performAndWait {
            guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
                return
            }
            self.setupAppExtensions(defaultAccount: account)
        }
    }

    @objc public func setupAppExtensions(defaultAccount: WPAccount) {
        let shareExtensionService = ShareExtensionService()
        let notificationSupportService = NotificationSupportService()

        guard let defaultBlog = defaultAccount.defaultBlog, !defaultBlog.isDeleted else {
            DispatchQueue.main.async {
                shareExtensionService.removeShareExtensionConfiguration()
                notificationSupportService.deleteServiceExtensionToken()
            }
            return
        }

        let defaultAccountObjectID = TaggedManagedObjectID(defaultAccount)
        let siteID = defaultBlog.dotComID?.intValue
        let siteName = defaultBlog.settings?.name

        DispatchQueue.main.async {
            do {
                let defaultAccount = try self.coreDataStack.mainContext.existingObject(with: defaultAccountObjectID)

                if let siteID, let siteName {
                    shareExtensionService.storeDefaultSiteID(siteID, defaultSiteName: siteName)
                } else {
                    wpAssertionFailure("siteID and/or siteName missing")
                }

                if let authToken = defaultAccount.authToken {
                    shareExtensionService.storeToken(authToken)
                    notificationSupportService.storeToken(authToken)
                } else {
                    wpAssertionFailure("authToken missing")
                }

                shareExtensionService.storeUsername(defaultAccount.username)
                notificationSupportService.storeUsername(defaultAccount.username)

                if let userID = defaultAccount.userID?.stringValue {
                    notificationSupportService.storeUserID(userID)
                } else {
                    wpAssertionFailure("userID missing")
                }
            } catch {
                wpAssertionFailure("failed to fetch the default account")
            }
        }
    }

    /// Loads the default WordPress account's cookies into shared cookie storage.
    ///
    static func loadDefaultAccountCookies() {
        guard
            let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext),
            let auth = RequestAuthenticator(account: account),
            let url = URL(string: WPComDomain)
        else {
            return
        }
        auth.request(url: url, cookieJar: HTTPCookieStorage.shared) { _ in
            // no op
        }
    }

}
