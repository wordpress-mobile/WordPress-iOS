
import UIKit

/// In Site Creation, both Verticals & Domains coordinate table view header appearance, keyboard behavior, & offsets.
/// This class manages that shared behavior.
///
final class TableViewOffsetCoordinator {

    // MARK: Properties
    private struct Constants {
        static let headerAnimationDuration  = Double(0.25)  // matches current system keyboard transition duration
        static let topMargin                = CGFloat(36)
        static let domainHeaderSection      = 0
    }

    /// The table view to coordinate
    private weak var tableView: UITableView?

    //// The view containing the toolbar
    private weak var footerControlContainer: UIView?

    //// The toolbar
    private weak var footerControl: UIView?

    //// The constraint linking the bottom of the footerControl to its container
    private weak var toolbarBottomConstraint: NSLayoutConstraint?

    /// Tracks the content offset introduced by the keyboard being presented
    private var keyboardContentOffset = CGFloat(0)

    /// To avoid wasted animations, we track whether or not we have already adjusted the table view
    private var tableViewHasBeenAdjusted = false

    /// Track the status of the toolbar, wether we have adjusted its position or remains at its initial location
    private var toolbarHasBeenAdjusted = false

    // MARK: TableViewOffsetCoordinator

    /// Initializes a table view offset coordinator with the specified table view.
    ///
    /// - Parameter tableView: the table view to manage
    /// - Parameter footerControlContainer: the view containing the toolbar
    /// - Parameter toolbar: a view that needs to be offset in coordination with the table view
    /// - Parameter toolbarBottomConstraint: the constraint linking the bottom if footerControlContainer and toolbar
    ///
    init(coordinated tableView: UITableView, footerControlContainer: UIView? = nil, footerControl: UIView? = nil, toolbarBottomConstraint: NSLayoutConstraint? = nil) {
        self.tableView = tableView
        self.footerControlContainer = footerControlContainer
        self.footerControl = footerControl
        self.toolbarBottomConstraint = toolbarBottomConstraint
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
                tableView.headerView(forSection: Constants.domainHeaderSection)?.isHidden = true
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

            let finalOffset: UIEdgeInsets
            if let footerControl = self.footerControl, self.toolbarHasBeenAdjusted == true {
                let toolbarHeight = footerControl.frame.size.height
                finalOffset = UIEdgeInsets(top: -1 * toolbarHeight,
                    left: 0, bottom: toolbarHeight, right: 0)
            } else {
                finalOffset = .zero
            }
            tableView.contentInset = finalOffset
            tableView.scrollIndicatorInsets = finalOffset
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

        adjustToolbarOffsetIfNeeded()
    }

    @objc
    private func keyboardWillHide(_ notification: Foundation.Notification) {
        keyboardContentOffset = 0
        toolbarHasBeenAdjusted = false
        toolbarBottomConstraint?.constant = 0
    }

    private func adjustToolbarOffsetIfNeeded() {
        guard let footerControl = footerControl, let footerControlContainer = footerControlContainer else {
            return
        }

        var constraintConstant = keyboardContentOffset

        let bottomInset = footerControlContainer.safeAreaInsets.bottom
        constraintConstant -= bottomInset

        if let header = tableView?.tableHeaderView as? TitleSubtitleTextfieldHeader {
            let textFieldFrame = header.textField.frame

            let newToolbarFrame = footerControl.frame.offsetBy(dx: 0.0, dy: -1 * constraintConstant)

            toolbarBottomConstraint?.constant = constraintConstant
            footerControlContainer.setNeedsUpdateConstraints()

            UIView.animate(withDuration: Constants.headerAnimationDuration, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                guard let self = self, let tableView = self.tableView else {
                    return
                }

                if textFieldFrame.intersects(newToolbarFrame) {
                    let contentInsets = UIEdgeInsets(top: -1 * footerControl.frame.height, left: 0.0, bottom: constraintConstant + footerControl.frame.height, right: 0.0)
                    self.toolbarHasBeenAdjusted = true
                    tableView.contentInset = contentInsets
                    tableView.scrollIndicatorInsets = contentInsets
                }
                footerControlContainer.layoutIfNeeded()
                }, completion: { [weak self] _ in
                    self?.tableViewHasBeenAdjusted = false
            })
        }
    }

    func startListeningToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    func showBottomToolbar() {
        footerControl?.isHidden = false
    }

    func hideBottomToolbar() {
        footerControl?.isHidden = true
    }
}
