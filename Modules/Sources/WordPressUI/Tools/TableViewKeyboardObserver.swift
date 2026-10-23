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
        let key = UIResponder.keyboardFrameEndUserInfoKey
        guard let tableView,
              let keyboardFrame = (notification.userInfo?[key] as? NSValue)?.cgRectValue else {
            return
        }

        // The keyboard frame is in screen coordinates. Convert it into the table view and use the
        // overlap height, which is correct for any window size, placement, or orientation.
        let keyboardFrameInTableView: CGRect
        if let screenCoordinateSpace = (notification.object as? UIScreen)?.coordinateSpace {
            keyboardFrameInTableView = tableView.convert(keyboardFrame, from: screenCoordinateSpace)
        } else {
            keyboardFrameInTableView = tableView.convert(keyboardFrame, from: nil)
        }

        var inset = originalInset
        inset.bottom += tableView.bounds.intersection(keyboardFrameInTableView).height
        tableView.contentInset = inset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView?.contentInset = originalInset
    }
}
