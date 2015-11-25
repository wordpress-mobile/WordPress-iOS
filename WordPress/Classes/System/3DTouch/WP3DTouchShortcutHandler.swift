import UIKit
import WordPressComAnalytics

public class WP3DTouchShortcutHandler: NSObject
{
    enum ShortcutIdentifier: String {
        case LogIn
        case NewPost
        case NewPhotoPost
        case Stats
        case Notifications
        
        init?(fullType: String) {
            guard let last = fullType.componentsSeparatedByString(".").last else {
                        return nil
                    }
            
            self.init(rawValue: last)
        }
        
        var type: String {
            return NSBundle.mainBundle().bundleIdentifier! + ".\(self.rawValue)"
        }
    }
    
    static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"
    
    public func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        guard let shortCutType = shortcutItem.type as String? else {
                    return false
                }
        
        let tabBarController: WPTabBarController = WPTabBarController.sharedInstance()
        
        switch shortCutType {
            case ShortcutIdentifier.LogIn.type:
                WPAnalytics.track(.ShortcutLogIn)
                handled = true
                break
            case ShortcutIdentifier.NewPost.type:
                WPAnalytics.track(.ShortcutNewPost)
                tabBarController.showPostTabWithOptions([WPPostViewControllerOptionNotAnimated: true])
                handled = true
                break
            case ShortcutIdentifier.NewPhotoPost.type:
                WPAnalytics.track(.ShortcutNewPhotoPost)
                tabBarController.showPostTabWithOptions([WPPostViewControllerOptionOpenMediaPicker: true, WPPostViewControllerOptionNotAnimated: true])
                handled = true
                break
            case ShortcutIdentifier.Stats.type:
                WPAnalytics.track(.ShortcutStats)
                clearCurrentViewController()
                let blogService: BlogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                tabBarController.switchMySitesTabToStatsViewForBlog(blogService.lastUsedOrFirstBlog())
                handled = true
                break
            case ShortcutIdentifier.Notifications.type:
                WPAnalytics.track(.ShortcutNotifications)
                clearCurrentViewController()
                tabBarController.showNotificationsTab()
                handled = true
                break
            default:
                break
        }
        
        return handled
    }
    
    private func clearCurrentViewController() {
        WordPressAppDelegate.sharedInstance().window!.rootViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
}
