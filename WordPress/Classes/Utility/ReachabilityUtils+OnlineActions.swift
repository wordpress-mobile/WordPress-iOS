import Foundation

extension ReachabilityUtils {

    /// Performs the action when an internet connection is available
    /// If no internet connection is available an error message is displayed
    ///
    class func onAvailableInternetConnectionDo(_ action: () -> Void) {
        guard ReachabilityUtils.isInternetReachable() else {
            let title = NSLocalizedString("No Connection",
                                          comment: "Title of error prompt when no internet connection is available.")
            let message = NSLocalizedString("The Internet connection appears to be offline",
                                            comment: "Message of error prompt shown when a user tries to perform an action without an internet connection.")
            WPError.showAlert(withTitle: title, message: message)
            return
        }
        action()
    }
}
