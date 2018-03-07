
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

protocol NetworkStatusDelegate: class {
    func observeNetworkStatus()
    func networdStatusDidChange()
}

extension NetworkStatusDelegate where Self: UIViewController {
    func observeNetworkStatus() {
        let _ = ReachabilityObserver(delegate: self)
    }
}

final fileprivate class ReachabilityObserver: NSObject {
    private static var observerContext = 0
    private weak var delegate: NetworkStatusDelegate?

    init(delegate: NetworkStatusDelegate) {
        self.delegate = delegate
        super.init()

        configureObserver()
    }

    private func configureObserver() {
        if let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate {
            appDelegate.addObserver(self, forKeyPath: #keyPath(WordPressAppDelegate.connectionAvailable), options: [.new], context: &type(of: self).observerContext)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WordPressAppDelegate.connectionAvailable), let newValue = change?[.newKey] as? Bool {
            //
            print("======= rechability changed in my observer====")
        }
    }

    deinit {
        removeObserver(self, forKeyPath: #keyPath(WordPressAppDelegate.connectionAvailable))
    }
}
