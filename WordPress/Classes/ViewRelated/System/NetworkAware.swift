
/// Abstracts UI elements that need to be aware of the network connection status.
protocol NetworkAware {
    func connectionAvailable() -> Bool
    func handleConnectionError()
}

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
