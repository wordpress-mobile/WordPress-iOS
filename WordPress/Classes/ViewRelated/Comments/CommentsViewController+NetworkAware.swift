import UIKit

extension CommentsViewController: NetworkAwareUI {
    func contentIsEmpty() -> Bool {
        return tableViewHandler.resultsController.isEmpty()
    }

    @objc func noConnectionMessage() -> String {
        return NSLocalizedString("No internet connection. Some comments may be unavailable while offline.",
                                 comment: "Error message shown when the user is browsing Site Comments without an internet connection.")
    }

    @objc func connectionAvailable() -> Bool {
        return ReachabilityUtils.isInternetReachable()
    }

    @objc func handleConnectionError() {
        if shouldPresentAlert() {
            presentNoNetworkAlert()
        }
    }

    @objc func dismissConnectionErrorNotice() {
        dismissNoNetworkAlert()
    }
}

extension CommentsViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        refreshAndSyncIfNeeded()
    }
}
