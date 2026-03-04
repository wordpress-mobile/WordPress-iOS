import Foundation
import WordPressShared

extension ReachabilityUtils {

    @objc
    public static func showAlertNoInternetConnection() {
        ReachabilityAlert(retryBlock: nil).show()
    }

    @objc
    public static func showAlertNoInternetConnection(retryBlock: (() -> Void)? = nil) {
        ReachabilityAlert(retryBlock: retryBlock).show()
    }

    @objc
    public static func alertIsShowing() -> Bool {
        currentReachabilityAlert != nil
    }
}
