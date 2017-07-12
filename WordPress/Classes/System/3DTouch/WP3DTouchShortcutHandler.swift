import UIKit
import WordPressShared

open class WP3DTouchShortcutHandler: NSObject {
    enum ShortcutIdentifier: String {
        case LogIn
        case NewPost
        case NewPhotoPost
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

    static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"

    open func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        let tabBarController: WPTabBarController = WPTabBarController.sharedInstance()

        switch shortcutItem.type {
            case ShortcutIdentifier.LogIn.type:
                WPAnalytics.track(.shortcutLogIn)
                return true
            case ShortcutIdentifier.NewPost.type:
                WPAnalytics.track(.shortcutNewPost)
                tabBarController.showPostTab(animated: false, toMedia: false)
                return true
            case ShortcutIdentifier.NewPhotoPost.type:
                WPAnalytics.track(.shortcutNewPhotoPost)
                tabBarController.showPostTab(animated: false, toMedia: true)
                return true
            case ShortcutIdentifier.Stats.type:
                WPAnalytics.track(.shortcutStats)
                clearCurrentViewController()
                let blogService: BlogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                tabBarController.switchMySitesTabToStatsView(for: blogService.lastUsedOrFirstBlog())
                return true
            case ShortcutIdentifier.Notifications.type:
                WPAnalytics.track(.shortcutNotifications)
                clearCurrentViewController()
                tabBarController.showNotificationsTab()
                return true
            default:
                return false
        }
    }

    fileprivate func clearCurrentViewController() {
        WordPressAppDelegate.sharedInstance().window!.rootViewController?.dismiss(animated: false, completion: nil)
    }
}
