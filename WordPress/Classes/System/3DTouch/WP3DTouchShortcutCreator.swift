import UIKit
import WordPressAuthenticator


public protocol ApplicationShortcutsProvider {
    var shortcutItems: [UIApplicationShortcutItem]? { get set }
    var is3DTouchAvailable: Bool { get }
}

extension UIApplication: ApplicationShortcutsProvider {
    @objc public var is3DTouchAvailable: Bool {
        return mainWindow?.traitCollection.forceTouchCapability == .available
    }
}

open class WP3DTouchShortcutCreator: NSObject {
    enum LoggedIn3DTouchShortcutIndex: Int {
        case notifications = 0,
        stats,
        newPost
    }

    var shortcutsProvider: ApplicationShortcutsProvider
    @objc let mainContext = ContextManager.sharedInstance().mainContext

    fileprivate let logInShortcutIconImageName = "icon-shortcut-signin"
    fileprivate let notificationsShortcutIconImageName = "icon-shortcut-notifications"
    fileprivate let statsShortcutIconImageName = "icon-shortcut-stats"
    fileprivate let newPostShortcutIconImageName = "icon-shortcut-new-post"

    public init(shortcutsProvider: ApplicationShortcutsProvider) {
        self.shortcutsProvider = shortcutsProvider
        super.init()
        registerForNotifications()
    }

    public convenience override init() {
        self.init(shortcutsProvider: UIApplication.shared)
    }

    @objc open func createShortcutsIf3DTouchAvailable(_ loggedIn: Bool) {
        guard shortcutsProvider.is3DTouchAvailable else {
            return
        }

        if loggedIn {
            if hasBlog() {
                createLoggedInShortcuts()
            } else {
                clearShortcuts()
            }
        } else {
            createLoggedOutShortcuts()
        }
    }

    fileprivate func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(WP3DTouchShortcutCreator.createLoggedInShortcuts), name: NSNotification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(WP3DTouchShortcutCreator.createLoggedInShortcuts), name: .WPRecentSitesChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(WP3DTouchShortcutCreator.createLoggedInShortcuts), name: .WPBlogUpdated, object: nil)
        notificationCenter.addObserver(self, selector: #selector(WP3DTouchShortcutCreator.createLoggedInShortcuts), name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
    }

    fileprivate func loggedOutShortcutArray() -> [UIApplicationShortcutItem] {
        let logInShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.type,
                                                   localizedTitle: NSLocalizedString("Log In", comment: "Log In 3D Touch Shortcut"),
                                                localizedSubtitle: nil,
                                                             icon: UIApplicationShortcutIcon(templateImageName: logInShortcutIconImageName),
                                                         userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.rawValue as NSSecureCoding])

        return [logInShortcut]
    }

    fileprivate func loggedInShortcutArray() -> [UIApplicationShortcutItem] {
        var defaultBlogName: String?
        if Blog.count(in: mainContext) > 1 {
            defaultBlogName = Blog.lastUsedOrFirst(in: mainContext)?.settings?.name
        }

        let notificationsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.type,
                                                           localizedTitle: NSLocalizedString("Notifications", comment: "Notifications 3D Touch Shortcut"),
                                                        localizedSubtitle: nil,
                                                                     icon: UIApplicationShortcutIcon(templateImageName: notificationsShortcutIconImageName),
                                                                 userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.rawValue as NSSecureCoding])

        let statsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.type,
                                                   localizedTitle: NSLocalizedString("Stats", comment: "Stats 3D Touch Shortcut"),
                                                localizedSubtitle: defaultBlogName,
                                                             icon: UIApplicationShortcutIcon(templateImageName: statsShortcutIconImageName),
                                                         userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.rawValue as NSSecureCoding])

        let newPostShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.type,
                                                     localizedTitle: NSLocalizedString("New Post", comment: "New Post 3D Touch Shortcut"),
                                                  localizedSubtitle: defaultBlogName,
                                                               icon: UIApplicationShortcutIcon(templateImageName: newPostShortcutIconImageName),
                                                           userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.rawValue as NSSecureCoding])

        return [notificationsShortcut, statsShortcut, newPostShortcut]
    }

    @objc fileprivate func createLoggedInShortcuts() {

        DispatchQueue.main.async {[weak self]() in
            guard let strongSelf = self else {
                return
            }
            let entireShortcutArray = strongSelf.loggedInShortcutArray()
            var visibleShortcutArray = [UIApplicationShortcutItem]()
            let jetpackFeaturesEnabled = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()

            if jetpackFeaturesEnabled && strongSelf.hasWordPressComAccount() {
                visibleShortcutArray.append(entireShortcutArray[LoggedIn3DTouchShortcutIndex.notifications.rawValue])
            }

            if jetpackFeaturesEnabled && strongSelf.doesCurrentBlogSupportStats() {
                visibleShortcutArray.append(entireShortcutArray[LoggedIn3DTouchShortcutIndex.stats.rawValue])
            }

            if AppConfiguration.allowsNewPostShortcut {
                visibleShortcutArray.append(entireShortcutArray[LoggedIn3DTouchShortcutIndex.newPost.rawValue])
            }

            strongSelf.shortcutsProvider.shortcutItems = visibleShortcutArray
        }
    }

    fileprivate func clearShortcuts() {
        shortcutsProvider.shortcutItems = nil
    }

    fileprivate func createLoggedOutShortcuts() {
        shortcutsProvider.shortcutItems = loggedOutShortcutArray()
    }

    fileprivate func is3DTouchAvailable() -> Bool {
        let window = UIApplication.shared.mainWindow

        return window?.traitCollection.forceTouchCapability == .available
    }

    fileprivate func hasWordPressComAccount() -> Bool {
        return AccountHelper.isDotcomAvailable()
    }

    fileprivate func doesCurrentBlogSupportStats() -> Bool {
        guard let currentBlog = Blog.lastUsedOrFirst(in: mainContext) else {
            return false
        }

        return hasWordPressComAccount() && currentBlog.supports(BlogFeature.stats)
    }

    fileprivate func hasBlog() -> Bool {
        return Blog.count(in: mainContext) > 0
    }
}
