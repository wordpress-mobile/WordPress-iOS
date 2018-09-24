import UIKit
import WordPressFlux

protocol TextCopyable {
    var text: String? { get }
    func copyAction()
}

extension TextCopyable {
    func copyAction() {
        let copyAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        copyAlertController.presentAlertForCopy(self.text) { notice in
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        }
    }
}
