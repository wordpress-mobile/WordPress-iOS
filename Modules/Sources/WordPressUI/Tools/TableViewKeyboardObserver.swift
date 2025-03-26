import UIKit

public final class TableViewKeyboardObserver {
    public weak var tableView: UITableView? {
        didSet {
            originalInset = tableView?.contentInset ?? .zero
        }
    }

    private var originalInset: UIEdgeInsets = .zero

    public init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(TableViewKeyboardObserver.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(TableViewKeyboardObserver.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Foundation.Notification) {
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

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView?.contentInset = originalInset
    }
}
