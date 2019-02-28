import UIKit

extension CommentsViewController: NetworkAwareUI {
    func contentIsEmpty() -> Bool {
        return tableViewHandler.resultsController.isEmpty()
    }

    @objc func noConnectionMessage() -> String {
        return ReachabilityUtils.noConnectionMessage()
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
