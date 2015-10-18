import UIKit

public class WP3DTouchShortcutCreator: NSObject
{
    var application: UIApplication!
    
    override init() {
        application = UIApplication.sharedApplication()
    }
    
    public func createShortcuts(loggedIn loggedIn: Bool, defaultBlogName: String) {
        if loggedIn {
            createLoggedInShortcutsWithDefaultBlogName(defaultBlogName)
        } else {
            createLoggedOutShortcuts()
        }
    }
    
    private func createLoggedInShortcutsWithDefaultBlogName(defaultBlogName: String) {
        let newPostShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.type,
                                                     localizedTitle: NSLocalizedString("New Post", comment: "New Post"),
                                                  localizedSubtitle: defaultBlogName,
                                                               icon: UIApplicationShortcutIcon(templateImageName: "icon-posts-add"),
                                                                                                        userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPost.rawValue])
        let newPhotoPostShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPhotoPost.type,
                                                          localizedTitle: NSLocalizedString("New Photo Post", comment: "New Photo Post"),
                                                       localizedSubtitle: defaultBlogName,
                                                                    icon: UIApplicationShortcutIcon(templateImageName: "photos"),
                                                                                                             userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.NewPhotoPost.rawValue])
        let statsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.type,
                                                   localizedTitle: NSLocalizedString("Stats", comment: "Stats"),
                                                localizedSubtitle: defaultBlogName,
                                                             icon: UIApplicationShortcutIcon(templateImageName: "icon-menu-stats"),
                                                                                                      userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Stats.rawValue])
        let notificationsShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.type,
                                                           localizedTitle: NSLocalizedString("Notifications", comment: "Notifications"),
                                                        localizedSubtitle: nil,
                                                                     icon: UIApplicationShortcutIcon(templateImageName: "icon-tab-notifications"),
                                                                                                              userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.Notifications.rawValue])
        
        application.shortcutItems = [notificationsShortcut, statsShortcut, newPhotoPostShortcut, newPostShortcut]
    }
    
    private func createLoggedOutShortcuts() {
        let logInShortcut = UIMutableApplicationShortcutItem(type: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.type,
                                                     localizedTitle: NSLocalizedString("Log In", comment: "Log In"),
                                                  localizedSubtitle: nil,
                                                               icon: UIApplicationShortcutIcon(templateImageName: "icon-tab-mysites"),
                                                                                                        userInfo: [WP3DTouchShortcutHandler.applicationShortcutUserInfoIconKey: WP3DTouchShortcutHandler.ShortcutIdentifier.LogIn.rawValue])
        
        application.shortcutItems = [logInShortcut]
    }
}
