
import UIKit

/// In Site Creation, both Verticals & Domains coordinate table view header appearance, keyboard behavior, & offsets.
/// This class manages that shared behavior.
///
final class TableViewOffsetCoordinator {

    // MARK: Properties
    private struct Constants {
        static let headerAnimationDuration  = Double(0.25)  // matches current system keyboard transition duration
        static let topMargin                = CGFloat(36)
    }

    /// The table view to coordinate
    private weak var tableView: UITableView?

    /// The value of the bottom constraint constant is set in response to the keyboard appearance
    private var keyboardContentOffset = CGFloat(0)

    /// To avoid wasted animations, we track whether or not we have already adjusted the table view
    private var tableViewHasBeenAdjusted = false

    // MARK: TableViewOffsetCoordinator

    /// Initializes a table view offset coordinator with the specified table view.
    ///
    /// - Parameter tableView: the table view to manage
    ///
    init(coordinated tableView: UITableView) {
        self.tableView = tableView
    }

    // MARK: Internal behavior

    /// This method hides the table view header and adjusts the content offset so that the input text field is visible.
    ///
    func adjustTableOffsetIfNeeded() {
        guard let tableView = tableView, keyboardContentOffset > 0, tableViewHasBeenAdjusted == false else {
            return
        }

        let topInset: CGFloat
        if WPDeviceIdentification.isiPhone(), let header = tableView.tableHeaderView as? TitleSubtitleTextfieldHeader {
            let textfieldFrame = header.textField.frame
            topInset = textfieldFrame.origin.y - Constants.topMargin
        } else {
            topInset = 0
        }

        let bottomInset: CGFloat
        if WPDeviceIdentification.isiPad() && UIDevice.current.orientation.isPortrait {
            bottomInset = 0
        } else {
            bottomInset = keyboardContentOffset
        }

        let targetInsets = UIEdgeInsets(top: -topInset, left: 0, bottom: bottomInset, right: 0)

        UIView.animate(withDuration: Constants.headerAnimationDuration, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            guard let self = self, let tableView = self.tableView else {
                return
            }

            tableView.contentInset = targetInsets
            tableView.scrollIndicatorInsets = targetInsets
            if WPDeviceIdentification.isiPhone(), let header = tableView.tableHeaderView as? TitleSubtitleTextfieldHeader {
                header.titleSubtitle.alpha = 0.0
            }
        }, completion: { [weak self] _ in
            self?.tableViewHasBeenAdjusted = true
        })
    }

    /// This method resets the table view header and the content offset to the default state.
    ///
    func resetTableOffsetIfNeeded() {
        guard WPDeviceIdentification.isiPhone(), tableViewHasBeenAdjusted == true else {
            return
        }

        UIView.animate(withDuration: Constants.headerAnimationDuration, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            guard let self = self, let tableView = self.tableView else {
                return
            }

            tableView.contentInset = .zero
            tableView.scrollIndicatorInsets = .zero
            if WPDeviceIdentification.isiPhone(), let header = tableView.tableHeaderView as? TitleSubtitleTextfieldHeader {
                header.titleSubtitle.alpha = 1.0
            }
        }, completion: { [weak self] _ in
            self?.tableViewHasBeenAdjusted = false
        })
    }

    @objc
    func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let payload = KeyboardInfo(notification) else {
            return
        }

        let keyboardScreenFrame = payload.frameEnd
        keyboardContentOffset = keyboardScreenFrame.height
    }

    func startListeningToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
}
