import Foundation
import Reachability

@objc
public class ReachabilityUtils: NSObject {

    @objc
    public private(set) static var internetReachability: Reachability?

    public static var connectionAvailable = false

    @objc
    public static func isInternetReachable() -> Bool {
        connectionAvailable
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

    public static func configure(
        notificationCenter: NotificationCenter = .default,
        reachability: Reachability? = .forInternetConnection()
    ) {
        // The fact that the reachability instance is nullable is only an Objective-C bridging byproduct.
        guard let internetReachability = reachability else {
            fatalError("Failed to acquire internet reachability. This should never happen.")
        }

        let reachableStateChangedHandler: NetworkReachable = { reachability in
            guard let reachability else { return }

            DispatchQueue.main.async {
                print(
                    "Reachability state changed. WiFi: \(reachability.isReachableViaWiFi()) WWAN: \(reachability.isReachableViaWWAN())"
                )
                let newValue = reachability.isReachable()
                connectionAvailable = newValue

                notificationCenter.post(
                    name: .reachabilityChanged,
                    object: self,
                    userInfo: [Notification.reachabilityKey: newValue]
                )
            }
        }

        internetReachability.reachableBlock = reachableStateChangedHandler
        internetReachability.unreachableBlock = reachableStateChangedHandler

        internetReachability.startNotifier()

        self.internetReachability = internetReachability
        connectionAvailable = internetReachability.isReachable()
    }
}
