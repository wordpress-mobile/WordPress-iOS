import Foundation
import WordPressFlux

@objc extension UIViewController {
    @objc func displayNotice(title: String, message: String? = nil) {
        displayActionableNotice(title: title, message: message)
    }

    @objc func displayActionableNotice(title: String, message: String? = nil, actionTitle: String? = nil, actionHandler: ((Bool) -> Void)? = nil) {
        let notice = Notice(title: title, message: message, actionTitle: actionTitle, actionHandler: actionHandler)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    @objc func dismissNotice() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }
}
