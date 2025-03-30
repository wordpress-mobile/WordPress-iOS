import Foundation

public extension Notification {
    static let reachabilityKey = "org.wordpress.reachability"
}

public extension Notification.Name {
    /// - warning: Using a different name that auto-imported `kReachabilityChangedNotification`.
    static var reachabilityUpdated: Notification.Name {
        return Notification.Name("\(Notification.reachabilityKey).updated")
    }
}

@objc extension NSNotification {
    public static let ReachabilityUpdatedNotification = Notification.Name.reachabilityUpdated
}
