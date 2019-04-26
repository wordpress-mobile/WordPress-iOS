import Foundation
import WordPressFlux

extension ReachabilityUtils {
    private enum DefaultNoConnectionMessage {
        static let title = NSLocalizedString("No Connection",
                comment: "Title of error prompt when no internet connection is available.")
        static let message = noConnectionMessage()
        static let tag: Notice.Tag = "ReachabilityUtils.NoConnection"
    }

    /// Performs the action when an internet connection is available
    /// If no internet connection is available an error message is displayed
    ///
    @objc class func onAvailableInternetConnectionDo(_ action: () -> Void) {
        guard ReachabilityUtils.isInternetReachable() else {
            WPError.showAlert(withTitle: DefaultNoConnectionMessage.title, message: DefaultNoConnectionMessage.message)
            return
        }
        action()
    }

    /// Performs the action once when internet becomes reachable.
    ///
    /// This returns an opaque value similar to what
    /// NotificationCenter.addObserver(forName:object:queue:using:) returns.
    /// You can keep a reference to this if you want to cancel the observer by
    /// calling NotificationCenter.removeObserver(_:)
    ///
    @discardableResult
    @objc class func observeOnceInternetAvailable(action: @escaping () -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.observeOnce(
            forName: .reachabilityChanged,
            object: nil,
            queue: .main,
            using: { _ in action() },
            filter: { (notification) in
                return notification.userInfo?[Foundation.Notification.reachabilityKey] as? Bool == true
        })
    }

    /// Shows a generic non-blocking "No Connection" error message to the user.
    ///
    /// We use a Snackbar instead of a literal Alert because, for internet connection errors,
    /// Alerts can be disruptive.
    @objc static func showNoInternetConnectionNotice(message: String = noConnectionMessage()) {
        // An empty title is intentional to only show a single regular font message.
        let notice = Notice(title: "", message: message, tag: DefaultNoConnectionMessage.tag)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    /// Dismiss the currently shown Notice if it was created using showNoInternetConnectionNotice()
    @objc static func dismissNoInternetConnectionNotice() {
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(DefaultNoConnectionMessage.tag))
    }
}
