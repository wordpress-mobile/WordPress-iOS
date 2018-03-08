
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

fileprivate struct NetworkStatusAssociatedKeys {
    static var associatedObjectKey = "com.later.error.notification.receiver"
}

protocol NetworkStatusDelegate: class {
    func observeNetworkStatus()

    func networdStatusDidChange(active: Bool)
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

//    private(set) var reachabilityObserver: ReachabilityObserver {
//        get {
//            guard let value = objc_getAssociatedObject(self, &NetworkStatusAssociatedKeys.observer) as? ReachabilityObserver else {
//                return ReachabilityObserver(delegate: self)
//            }
//            return value
//        }
//        set(newValue) {
//            objc_setAssociatedObject(self, &NetworkStatusAssociatedKeys.observer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//
//    func observeNetworkStatus() {
//        reachabilityObserver = ReachabilityObserver(delegate: self)
//    }
}

//@objc final class ReachabilityObserver: NSObject {
//    private static var observerContext = 0
//    weak var delegate: NetworkStatusDelegate?
//
//    init(delegate: NetworkStatusDelegate) {
//        self.delegate = delegate
//        super.init()
//
//        configureObserver()
//    }
//
//    private func configureObserver() {
//        if let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate {
//            appDelegate.addObserver(self, forKeyPath: #keyPath(WordPressAppDelegate.connectionAvailable), options: [.old, .new], context: &type(of: self).observerContext)
//        }
//    }
//
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == #keyPath(WordPressAppDelegate.connectionAvailable),
//            let oldValue = change?[.oldKey] as? Bool,
//            let newValue = change?[.newKey] as? Bool {
//            if oldValue != newValue {
//                delegate?.networdStatusDidChange(active: newValue)
//            }
//        }
//    }
//
//    deinit {
//        removeObserver(self, forKeyPath: #keyPath(WordPressAppDelegate.connectionAvailable))
//    }
//}


fileprivate final class ReachabilityNotificationObserver: NSObject {
    private weak var delegate: NetworkStatusDelegate?

    init(delegate: NetworkStatusDelegate) {
        self.delegate = delegate
        super.init()
    }

    func observeErrors() {
        NotificationCenter.default.addObserver(self, selector: #selector(receive), name: .reachabilityChanged, object: nil)
    }

    @objc func receive(notification: Foundation.Notification) {
        if let newValue = notification.userInfo?[Foundation.Notification.reachabilityKey] as? Bool {
            delegate?.networdStatusDidChange(active: newValue)
        }
    }
}
