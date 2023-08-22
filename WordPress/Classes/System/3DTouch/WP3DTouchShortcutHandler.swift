import UIKit
import WordPressShared

open class WP3DTouchShortcutHandler: NSObject {
    enum ShortcutIdentifier: String {
        case LogIn
        case NewPost
        case Stats
        case Notifications

        init?(fullType: String) {
            guard let last = fullType.components(separatedBy: ".").last else {
                return nil
            }

            self.init(rawValue: last)
        }

        var type: String {
            return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
        }
    }

    @objc static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"

    @objc open func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        let rootViewPresenter = RootViewCoordinator.sharedPresenter

        switch shortcutItem.type {
            case ShortcutIdentifier.LogIn.type:
                WPAnalytics.track(.shortcutLogIn)
                return true
            case ShortcutIdentifier.NewPost.type:
                WPAnalytics.track(.shortcutNewPost)
                rootViewPresenter.showPostTab(animated: false)
                return true
            case ShortcutIdentifier.Stats.type:
                WPAnalytics.track(.shortcutStats)
                clearCurrentViewController()
                if let mainBlog = Blog.lastUsedOrFirst(in: ContextManager.sharedInstance().mainContext) {
                    rootViewPresenter.mySitesCoordinator.showStats(for: mainBlog)
                }
                return true
            case ShortcutIdentifier.Notifications.type:
                WPAnalytics.track(.shortcutNotifications)
                clearCurrentViewController()
                rootViewPresenter.showNotificationsTab()
                return true
            default:
                return false
        }
    }

    fileprivate func clearCurrentViewController() {
        WordPressAppDelegate.shared?.window?.rootViewController?.dismiss(animated: false)
    }
}
