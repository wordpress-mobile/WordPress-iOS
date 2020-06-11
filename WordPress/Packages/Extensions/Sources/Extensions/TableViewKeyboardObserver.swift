import UIKit

public class TableViewKeyboardObserver: NSObject {
    public weak var tableView: UITableView? {
        didSet {
            originalInset = tableView?.contentInset ?? .zero
        }
    }

    public var originalInset: UIEdgeInsets = .zero

    public override init() {
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

    @objc private func keyboardWillShow(_ notification: Foundation.Notification) {
        let key: String = UIResponder.keyboardFrameBeginUserInfoKey

        guard let keyboardFrame: CGRect = (notification.userInfo?[key] as? NSValue)?.cgRectValue else {
            return
        }

        var inset: UIEdgeInsets = originalInset

        if UIApplication.shared.statusBarOrientation.isPortrait {
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
