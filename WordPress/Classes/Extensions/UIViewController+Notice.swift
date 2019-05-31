import Foundation
import WordPressFlux
import WordPressShared


extension UIViewController {
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
                            actionTitle: buttonTitle) { _ in
                                let context = ContextManager.sharedInstance().mainContext
                                let service = ReaderTopicService(managedObjectContext: context)
                                service.toggleSubscribingNotifications(for: siteID.intValue, subscribe: true, {
                                    WPAnalytics.track(.readerListNotificationEnabled)
                                })
        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}

@objc extension UIViewController {
    @objc func displayNotice(title: String, message: String? = nil) {
        let notice = Notice(title: title, message: message)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    @objc func dismissNotice() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }
}
