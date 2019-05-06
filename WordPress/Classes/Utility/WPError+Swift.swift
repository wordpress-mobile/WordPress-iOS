
import Foundation
import WordPressFlux

extension WPError {
    private static let noticeTag: Notice.Tag = "WPError.Networking"

    /// Show a Notice with the message taken from the given `error`
    ///
    /// This is similar to `showNetworkingAlertWithError` except this uses a Notice instead of
    /// an Alert.
    ///
    /// - parameter error: Assumed to be an error from a networking call
    static func showNetworkingNotice(title: String, error: NSError) {
        if showWPComSigninIfErrorIsInvalidAuth(error) {
            return
        }

        let titleAndMessage = self.titleAndMessage(fromNetworkingError: error, desiredTitle: title)

        let notice = Notice(title: titleAndMessage["title"] ?? "",
                            message: titleAndMessage["message"],
                            tag: noticeTag)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    /// Dismiss the currently shown Notice if it was created using showNetworkingNotice()
    static func dismissNetworkingNotice() {
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(noticeTag))
    }
}
