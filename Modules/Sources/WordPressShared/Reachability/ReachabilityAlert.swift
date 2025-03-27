import Foundation

var currentReachabilityAlert: ReachabilityAlert?

class ReachabilityAlert: NSObject {

    let retryBlock: (() -> Void)?

    init(retryBlock: (() -> Void)?) {
        self.retryBlock = retryBlock
    }

    func show() {
        guard currentReachabilityAlert == nil else { return }

        let title = NSLocalizedString("reachability-utils.alert.title", value: "No Connection", comment: "")
        let message = ReachabilityUtils.noConnectionMessage()
        let cancelActionTitle = NSLocalizedString("reachability-utils.alert.cancel", value: "OK", comment: "")
        let retryActionTitle = NSLocalizedString("reachability-utils.alert.retry", value: "Retry?", comment: "")

        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alertController.addAction(
            UIAlertAction(title: cancelActionTitle, style: .cancel) { _ in
                currentReachabilityAlert = nil
            }
        )

        if let retryBlock {
            alertController.addAction(
                UIAlertAction(title: retryActionTitle, style: .default) { _ in
                    currentReachabilityAlert = nil
                    retryBlock()
                }
            )
        }

        // Note: This viewController might not be visible anymore
        alertController.presentFromRootViewController()

        currentReachabilityAlert = self
    }
}
