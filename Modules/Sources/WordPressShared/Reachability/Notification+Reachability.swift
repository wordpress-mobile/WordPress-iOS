import Foundation

public extension Notification {
    static let reachabilityKey = "org.wordpress.reachability"
}

public extension Notification.Name {
    static var reachabilityChanged: Notification.Name {
        return Notification.Name("\(Notification.reachabilityKey).changed")
    }
}

@objc extension NSNotification {
    public static let ReachabilityChangedNotification = Notification.Name.reachabilityChanged
}
