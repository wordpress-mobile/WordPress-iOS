import UIKit

public class ShortcutHandler3DTouch: NSObject
{
    enum ShortcutIdentifier: String {
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
        
        switch shortCutType {
            case ShortcutIdentifier.NewPost.type,
            ShortcutIdentifier.NewPhotoPost.type,
            ShortcutIdentifier.Stats.type:
                handled = true
                break
            case ShortcutIdentifier.Notifications.type:
                let tabBarController: WPTabBarController = WPTabBarController.sharedInstance()
                tabBarController.showNotificationsTab()
                handled = true
                break
            default:
                break
        }
        
        return handled
    }
}
