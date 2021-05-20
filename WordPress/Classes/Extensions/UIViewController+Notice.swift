import Foundation
import WordPressFlux

@objc extension UIViewController {
    @objc func displayNotice(title: String, message: String? = nil) {
        let notice = Notice(title: title, message: message)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    @objc func dismissNotice() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }
}
