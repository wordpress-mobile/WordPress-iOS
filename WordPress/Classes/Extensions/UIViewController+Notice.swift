import Foundation
import WordPressFlux

extension UIViewController {
    @objc func displayNotice(title: String, message: String? = nil) {
        displayActionableNotice(title: title, message: message)
    }

    @objc func displayActionableNotice(title: String,
                                       message: String? = nil,
                                       actionTitle: String? = nil,
                                       actionHandler: ((Bool) -> Void)? = nil) {
        displayActionableNotice(title: title, message: message, style: NormalNoticeStyle(), actionTitle: actionTitle, actionHandler: actionHandler)
    }

    // NoticeStyle is Swift only, so this method is needed to set it.
    func displayActionableNotice(title: String,
                                 message: String? = nil,
                                 style: NoticeStyle = NormalNoticeStyle(),
                                 actionTitle: String? = nil,
                                 actionHandler: ((Bool) -> Void)? = nil) {
        let notice = Notice(title: title, message: message, style: style, actionTitle: actionTitle, actionHandler: actionHandler)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    @objc func dismissNotice() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }
}
