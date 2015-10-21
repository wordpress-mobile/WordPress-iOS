import UIKit

public class WP3DTouchShortcutHandler: NSObject
{
    enum ShortcutIdentifier: String {
        case LogIn
        case NewPost
        case NewPhotoPost
        case Stats
        case Notifications
        
        init?(fullType: String) {
            guard let last = fullType.componentsSeparatedByString(".").last else { return nil }
            
            self.init(rawValue: last)
        }
        
        var type: String {
            let yo: String = NSBundle.mainBundle().bundleIdentifier! + ".\(self.rawValue)"
            return yo
        }
    }
    
    static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"
    
    public func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        guard let shortCutType = shortcutItem.type as String? else { return false }
        let tabBarController: WPTabBarController = WPTabBarController.sharedInstance()
        
        clearCurrentViewController()
        
        switch shortCutType {
            case ShortcutIdentifier.LogIn.type:
                handled = true
                break
            case ShortcutIdentifier.NewPost.type:
                tabBarController.showPostTab()
                handled = true
                break
            case ShortcutIdentifier.NewPhotoPost.type:
                tabBarController.showPostTabWithOptions(["media_picker": "yes"])
                handled = true
                break
            case ShortcutIdentifier.Stats.type:
                let blogService: BlogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                tabBarController.switchMySitesTabToStatsViewForBlog(blogService.lastUsedOrFirstBlog())
                handled = true
                break
            case ShortcutIdentifier.Notifications.type:
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
