import UIKit


// CommentsViewController is an Objective-C class, so in order for interop to work, it looks like we need to override these methods.
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
}
