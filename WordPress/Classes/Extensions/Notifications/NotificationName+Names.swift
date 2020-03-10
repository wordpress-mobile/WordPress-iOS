
import Foundation

/// Declares Notification Names
extension Foundation.Notification.Name {
    static var reachabilityChanged: Foundation.NSNotification.Name {
        return Foundation.Notification.Name("org.wordpress.reachability.changed")
    }

    static var showAllSavedForLaterPosts: Foundation.NSNotification.Name {
        return Foundation.Notification.Name("org.wordpress.reader.savedforlaterposts.showall")
    }
}

@objc extension NSNotification {
    public static let ShowAllSavedForLaterPostsNotification = Foundation.Notification.Name.showAllSavedForLaterPosts
    public static let ReachabilityChangedNotification = Foundation.Notification.Name.reachabilityChanged
}

/// Keys for Notification's userInfo dictionary
extension Foundation.Notification {
    static var reachabilityKey: String {
        return "org.wordpress.reachability"
    }
}
