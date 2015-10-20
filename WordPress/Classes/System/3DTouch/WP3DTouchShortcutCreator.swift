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
    
    override init() {
        application = UIApplication.sharedApplication()
        mainContext = ContextManager.sharedInstance().mainContext
        blogService = BlogService(managedObjectContext: mainContext)
    }
    
    public func createShortcuts(loggedIn: Bool) {
        if loggedIn {
            createLoggedInShortcuts()
        } else {
            createLoggedOutShortcuts()
        }
    }
    
    private func createLoggedInShortcuts() {
        var shortcutArray = loggedInShortcutArray()
        
        if hasWordPressComAccount() {
            application.shortcutItems?.append(shortcutArray[LoggedIn3DTouchShortcutIndex.Notifications.rawValue])
        }
        
        if isCurrentBlogDotComOrJetpackConnected() {
            application.shortcutItems?.append(shortcutArray[LoggedIn3DTouchShortcutIndex.Stats.rawValue])
        }
        
        application.shortcutItems?.append(shortcutArray[LoggedIn3DTouchShortcutIndex.NewPhotoPost.rawValue])
        application.shortcutItems?.append(shortcutArray[LoggedIn3DTouchShortcutIndex.NewPost.rawValue])
    }
    
    private func createLoggedOutShortcuts() {
        let logInShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.type,
                                                   localizedTitle: NSLocalizedString("Log In", comment: "Log In"),
                                                localizedSubtitle: nil,
                                                             icon: UIApplicationShortcutIcon(templateImageName: "icon-tab-mysites"),
                                                                                                      userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.rawValue])
        
        application.shortcutItems = [logInShortcut]
    }
    
    private func loggedInShortcutArray() -> [UIApplicationShortcutItem] {
        var defaultBlogName: String?
        if blogService.blogCountForAllAccounts() > 1 {
            defaultBlogName = blogService.lastUsedOrFirstBlog().blogName
        }
        
        let notificationsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.type,
                                                           localizedTitle: NSLocalizedString("Notifications", comment: "Notifications"),
                                                        localizedSubtitle: nil,
                                                                     icon: UIApplicationShortcutIcon(templateImageName: "icon-tab-notifications"),
                                                                                                              userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.rawValue])
        
        let statsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.type,
                                                   localizedTitle: NSLocalizedString("Stats", comment: "Stats"),
                                                localizedSubtitle: defaultBlogName,
                                                             icon: UIApplicationShortcutIcon(templateImageName: "icon-menu-stats"),
                                                                                                      userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.rawValue])
        
        let newPhotoPostShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPhotoPost.type,
                                                          localizedTitle: NSLocalizedString("New Photo Post", comment: "New Photo Post"),
                                                       localizedSubtitle: defaultBlogName,
                                                                    icon: UIApplicationShortcutIcon(templateImageName: "photos"),
                                                                                                             userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPhotoPost.rawValue])
        
        let newPostShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.type,
                                                     localizedTitle: NSLocalizedString("New Post", comment: "New Post"),
                                                  localizedSubtitle: defaultBlogName,
                                                               icon: UIApplicationShortcutIcon(templateImageName: "icon-posts-add"),
                                                                                                        userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.rawValue])
        
        return [notificationsShortcut, statsShortcut, newPhotoPostShortcut, newPostShortcut]
    }
    
    private func hasWordPressComAccount() -> Bool {
        let accountService = AccountService(managedObjectContext: mainContext)
        
        return accountService.defaultWordPressComAccount() != nil
    }
    
    private func isCurrentBlogDotComOrJetpackConnected() -> Bool {
        let currentBlog = blogService.lastUsedOrFirstBlog()
        
        return hasWordPressComAccount() && (currentBlog.jetpack.isConnected() || currentBlog.isHostedAtWPcom)
    }
}
