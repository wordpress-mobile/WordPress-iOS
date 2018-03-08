
import Foundation

extension Foundation.Notification.Name {
    static var reachabilityChanged: Foundation.NSNotification.Name {
        return Foundation.Notification.Name("org.wordpress.reachability.changed")
    }
}

extension Foundation.Notification {
    static var reachabilityKey: String {
        return "org.wordpress.reachability"
    }
}
