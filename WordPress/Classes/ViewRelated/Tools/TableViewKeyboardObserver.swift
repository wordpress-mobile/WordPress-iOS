import UIKit

class TableViewKeyboardObserver: NSObject {
    @objc weak var tableView: UITableView? {
        didSet {
            originalInset = tableView?.contentInset ?? .zero
        }
    }

    @objc var originalInset: UIEdgeInsets = .zero

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(TableViewKeyboardObserver.keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(TableViewKeyboardObserver.keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc func keyboardWillShow(_ notification: Foundation.Notification) {
        let key = UIResponder.keyboardFrameBeginUserInfoKey
        guard let keyboardFrame = (notification.userInfo?[key] as? NSValue)?.cgRectValue else {
            return
        }

        var inset = originalInset
        if tableView?.window?.windowScene?.interfaceOrientation.isPortrait == true {
            inset.bottom += keyboardFrame.height
        } else {
            inset.bottom += keyboardFrame.width
        }
        tableView?.contentInset = inset
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        tableView?.contentInset = originalInset
    }
}
