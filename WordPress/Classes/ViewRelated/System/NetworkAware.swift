
/// Abstracts elements that need to be aware of the network connection status.
protocol NetworkAware {
    func connectionAvailable() -> Bool
    func handleConnectionError()
}

/// Abstracts UI elements that need to be aware of the network connection status, and present user facing alerts.
protocol NetworkAwareUI: NetworkAware {
    func shouldPresentAlert() -> Bool
    func contentIsEmpty() -> Bool
    func presentNoNetworkAlert()
    func noConnectionMessage() -> String
}

extension NetworkAware {
    func connectionAvailable() -> Bool {
        return ReachabilityUtils.isInternetReachable()
    }
}

extension NetworkAwareUI {
    func shouldPresentAlert() -> Bool {
        return !connectionAvailable() && !contentIsEmpty()
    }

    func handleConnectionError() {
        if shouldPresentAlert() {
            presentNoNetworkAlert()
        }
    }

    func presentNoNetworkAlert() {
        let title = NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails.")
        let message = NSLocalizedString("The Internet connection appears to be offline.", comment: "Message of error prompt shown when a sync the user initiated fails.")
        WPError.showAlert(withTitle: title, message: message)
    }

    func noConnectionMessage() -> String {
        return ReachabilityUtils.noConnectionMessage()
    }
}

/// Implementations of this protocol will be notified when the network connection status changes. Implementations of this protocol must call the observeNetworkStatus method.
protocol NetworkStatusDelegate: class {
    func observeNetworkStatus()

    /// This method will be called, on the main thread, when the network connection changes status.
    ///
    /// - Parameter active: the new status of the network connection
    func networkStatusDidChange(active: Bool)
}

extension NetworkStatusDelegate where Self: UIViewController {
    func observeNetworkStatus() {
        receiver = ReachabilityNotificationObserver(delegate: self)
    }

    fileprivate var receiver: ReachabilityNotificationObserver? {
        get {
            return objc_getAssociatedObject(self, &NetworkStatusAssociatedKeys.associatedObjectKey) as? ReachabilityNotificationObserver
        }

        set {
            objc_setAssociatedObject(self, &NetworkStatusAssociatedKeys.associatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

fileprivate struct NetworkStatusAssociatedKeys {
    static var associatedObjectKey = "org.wordpress.networkstatus.notificationreceiver"
}

fileprivate final class ReachabilityNotificationObserver: NSObject {
    private weak var delegate: NetworkStatusDelegate?

    init(delegate: NetworkStatusDelegate) {
        self.delegate = delegate
        super.init()
        observeErrors()
    }

    private func observeErrors() {
        NotificationCenter.default.addObserver(self, selector: #selector(receive), name: .reachabilityChanged, object: nil)
    }

    @objc func receive(notification: Foundation.Notification) {
        if let newValue = notification.userInfo?[Foundation.Notification.reachabilityKey] as? Bool {
            DispatchQueue.main.async {
                self.delegate?.networkStatusDidChange(active: newValue)
            }
        }
    }
}
