import UIKit

public class WP3DTouchShortcutCreator: NSObject
{
    enum LoggedIn3DTouchShortcutIndex: Int {
        case Notifications = 0,
        Stats,
        NewPhotoPost,
        NewPost
    }
    
    var application: UIApplication!
    var mainContext: NSManagedObjectContext!
    var blogService: BlogService!
    
    private let logInShortcutIconImageName = "icon-shortcut-signin"
    private let notificationsShortcutIconImageName = "icon-shortcut-notifications"
    private let statsShortcutIconImageName = "icon-shortcut-stats"
    private let newPhotoPostShortcutIconImageName = "icon-shortcut-new-photo"
    private let newPostShortcutIconImageName = "icon-shortcut-new-post"
    
    override public init() {
        super.init()
        application = UIApplication.sharedApplication()
        mainContext = ContextManager.sharedInstance().mainContext
        blogService = BlogService(managedObjectContext: mainContext)
    }
    
    public func createShortcutsIf3DTouchAvailable(loggedIn: Bool) {
        if !is3DTouchAvailable() {
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
    
    private func loggedOutShortcutArray() -> [UIApplicationShortcutItem] {
        let logInShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.type,
                                                   localizedTitle: NSLocalizedString("Sign In", comment: "Sign In 3D Touch Shortcut"),
                                                localizedSubtitle: nil,
                                                             icon: UIApplicationShortcutIcon(templateImageName: logInShortcutIconImageName),
                                                         userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.rawValue])
        
        return [logInShortcut]
    }
    
    private func loggedInShortcutArray() -> [UIApplicationShortcutItem] {
        var defaultBlogName: String?
        if blogService.blogCountForAllAccounts() > 1 {
            defaultBlogName = blogService.lastUsedOrFirstBlog()?.settings?.name
        }
        
        let notificationsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.type,
                                                           localizedTitle: NSLocalizedString("Notifications", comment: "Notifications 3D Touch Shortcut"),
                                                        localizedSubtitle: nil,
                                                                     icon: UIApplicationShortcutIcon(templateImageName: notificationsShortcutIconImageName),
                                                                 userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.rawValue])
        
        let statsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.type,
                                                   localizedTitle: NSLocalizedString("Stats", comment: "Stats 3D Touch Shortcut"),
                                                localizedSubtitle: defaultBlogName,
                                                             icon: UIApplicationShortcutIcon(templateImageName: statsShortcutIconImageName),
                                                         userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.rawValue])
        
        let newPhotoPostShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPhotoPost.type,
                                                          localizedTitle: NSLocalizedString("New Photo Post", comment: "New Photo Post 3D Touch Shortcut"),
                                                       localizedSubtitle: defaultBlogName,
                                                                    icon: UIApplicationShortcutIcon(templateImageName: newPhotoPostShortcutIconImageName),
                                                                userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPhotoPost.rawValue])
        
        let newPostShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.type,
                                                     localizedTitle: NSLocalizedString("New Post", comment: "New Post 3D Touch Shortcut"),
                                                  localizedSubtitle: defaultBlogName,
                                                               icon: UIApplicationShortcutIcon(templateImageName: newPostShortcutIconImageName),
                                                           userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.rawValue])
        
        return [notificationsShortcut, statsShortcut, newPhotoPostShortcut, newPostShortcut]
    }
    
    private func createLoggedInShortcuts() {
        var entireShortcutArray = loggedInShortcutArray()
        var visibleShortcutArray = [UIApplicationShortcutItem]()
        
        if hasWordPressComAccount() {
            visibleShortcutArray.append(entireShortcutArray[LoggedIn3DTouchShortcutIndex.Notifications.rawValue])
        }
        
        if doesCurrentBlogSupportStats() {
            visibleShortcutArray.append(entireShortcutArray[LoggedIn3DTouchShortcutIndex.Stats.rawValue])
        }
        
        visibleShortcutArray.append(entireShortcutArray[LoggedIn3DTouchShortcutIndex.NewPhotoPost.rawValue])
        visibleShortcutArray.append(entireShortcutArray[LoggedIn3DTouchShortcutIndex.NewPost.rawValue])
        
        application.shortcutItems = visibleShortcutArray
    }
    
    private func clearShortcuts() {
        application.shortcutItems = nil
    }
    
    private func createLoggedOutShortcuts() {
        application.shortcutItems = loggedOutShortcutArray()
    }
    
    private func is3DTouchAvailable() -> Bool {
        let window = UIApplication.sharedApplication().keyWindow
        
        return window?.traitCollection.forceTouchCapability == .Available
    }
    
    private func hasWordPressComAccount() -> Bool {
        let accountService = AccountService(managedObjectContext: mainContext)
        
        return accountService.defaultWordPressComAccount() != nil
    }
    
    private func doesCurrentBlogSupportStats() -> Bool {
        guard let currentBlog = blogService.lastUsedOrFirstBlog() else {
            return false
        }
        
        return hasWordPressComAccount() && currentBlog.supports(BlogFeature.Stats)
    }
    
    private func hasBlog() -> Bool {
        return blogService.blogCountForAllAccounts() > 0
    }
}
