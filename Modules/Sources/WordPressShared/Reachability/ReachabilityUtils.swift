import Foundation
import Network

@objc
public class ReachabilityUtils: NSObject {

    private static var pathMonitor: NWPathMonitor?

    /// Whether the device currently has internet connectivity.
    ///
    /// The initial value is `false`. After `configure()` is called, `NWPathMonitor`
    /// updates it to the correct value on the next main run loop cycle. Subsequent
    /// changes are pushed automatically as the network state changes.
    public internal(set) static var connectionAvailable = false

    @objc
    public static func isInternetReachable() -> Bool {
        connectionAvailable
    }

    @objc
    public static func isReachableViaWiFi() -> Bool {
        pathMonitor?.currentPath.usesInterfaceType(.wifi) ?? false
    }

    @objc
    public static func showAlertNoInternetConnection() {
        ReachabilityAlert(retryBlock: nil).show()
    }

    @objc
    public static func showAlertNoInternetConnection(retryBlock: (() -> Void)? = nil) {
        ReachabilityAlert(retryBlock: retryBlock).show()
    }

    @objc
    public static func noConnectionMessage() -> String {
        NSLocalizedString(
            "reachability-utils.alert.utils",
            value: "The internet connection appears to be offline.",
            comment: "Message of error prompt shown when no internet connection is available"
        )
    }

    @objc
    public static func alertIsShowing() -> Bool {
        currentReachabilityAlert != nil
    }

    public static func configure() {
        guard pathMonitor == nil else { return }

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let newValue = path.status == .satisfied
            connectionAvailable = newValue

            NotificationCenter.default.post(
                name: .reachabilityUpdated,
                object: self,
                userInfo: [Notification.reachabilityKey: newValue]
            )
        }
        monitor.start(queue: .main)
        pathMonitor = monitor
        connectionAvailable = monitor.currentPath.status == .satisfied
    }
}
