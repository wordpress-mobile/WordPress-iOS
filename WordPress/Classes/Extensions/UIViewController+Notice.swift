import Foundation
import WordPressFlux
import WordPressShared


@objc extension UIViewController {
    /// Dispatch a Notice for subscribing notification action
    ///
    /// - Parameters:
    ///   - siteTitle: Title to display
    ///   - siteID: Site id to be used
    func dispatchSubscribingNotificationNotice(with siteTitle: String?, siteID: NSNumber?) {
        guard let siteTitle = siteTitle, let siteID = siteID else {
            return
        }

        let localizedTitle = NSLocalizedString("Following %@", comment: "Title for a notice informing the user that they've successfully followed a site. %@ is a placeholder for the name of the site.")
        let title = String(format: localizedTitle, siteTitle)
        let message = NSLocalizedString("Enable site notifications?", comment: "Message informing the user about the enable notifications action")
        let buttonTitle = NSLocalizedString("Enable", comment: "Button title about the enable notifications action")

        let notice = Notice(title: title,
                            message: message,
                            feedbackType: .success,
                            notificationInfo: nil,
                            actionTitle: buttonTitle) {
                                let context = ContextManager.sharedInstance().mainContext
                                let service = ReaderTopicService(managedObjectContext: context)
                                service.toggleSubscribingNotifications(for: siteID.intValue, subscribe: true, {
                                    WPAnalytics.track(.readerListNotificationEnabled)
                                })
        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
    /// This method is will allow viewControllers to present an alert controller (action sheet style) that
    /// provides a copy action to allow copying the text parameter to the clip board.
    /// Once copied, or on failure to copy, a notice will be posted using the dispacher so the user will know
    /// if copying to clipboard was successful
    func presentAlertAndCopyTextToClipboard(text: String?) {
        let successNoticeTitle = NSLocalizedString("Link Copied to Clipboard", comment: "")
        let failureNoticeTitle = NSLocalizedString("Copy to Clipboard failed", comment: "")
        let copyAlertController = UIAlertController.copyTextAlertController(text) { success in
            let title = success ? successNoticeTitle : failureNoticeTitle
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: title)))
        }
        copyAlertController?.presentFromRootViewController()
    }
}
