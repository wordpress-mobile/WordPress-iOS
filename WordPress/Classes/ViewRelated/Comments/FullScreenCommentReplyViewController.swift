
import UIKit
import Gridicons

/// FullscreenCommentReplyViewController is used when full screen commenting
/// After instantiating using `newEdit()` the class expects the `content` and `onExitFullscreen`
/// properties to be set.

class FullScreenCommentReplyViewController: EditCommentViewController {
    private struct Parameters {
        /// Determines the size of the replyButton
        static let replyButtonIconSize = CGSize(width: 21, height: 18)
    }

    /// The completion block that is called when the view is exiting fullscreen
    /// - Parameter: Bool, whether or not the calling view should trigger a save
    /// - Parameter: String, the updated comment content
    public var onExitFullscreen: ((Bool, String) -> ())?

    /// The save/reply button that is displayed in the rightBarButtonItem position
    private(set) var replyButton: UIButton!

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Comment", comment: "User facing, navigation bar title")

        setupReplyButton()
        setupNavigationItems()
        configureAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        enableRefreshButtonIfNeeded(animated: false)
    }

    // MARK: - UITextViewDelegate
    override func textViewDidBeginEditing(_ textView: UITextView) { }
    override func textViewDidEndEditing(_ textView: UITextView) { }

    override func contentDidChange() {
        enableRefreshButtonIfNeeded()
    }

    // MARK: - Actions
    @objc func btnSavePressed() {
        exitFullscreen(shouldSave: true)

    }

    @objc func btnExitFullscreenPressed() {
        exitFullscreen(shouldSave: false)
    }

    // MARK: - Private: Helpers

    /// Updates the iOS 13 title color
    private func configureAppearance() {
        if #available(iOS 13.0, *) {
            guard let navigationBar = navigationController?.navigationBar else {
                return
            }

            navigationBar.standardAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.text
            ]
        }
    }

    /// Creates the `replyButton` to be used as the `rightBarButtonItem`
    private func setupReplyButton() {
        replyButton = {
            let iconSize = Parameters.replyButtonIconSize
            let replyIcon = UIImage(named: "icon-comment-reply")

            let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: iconSize))
            button.setImage(replyIcon?.imageWithTintColor(WPStyleGuide.Reply.enabledColor), for: .normal)
            button.setImage(replyIcon?.imageWithTintColor(WPStyleGuide.Reply.disabledColor), for: .disabled)
            button.accessibilityLabel = NSLocalizedString("Reply", comment: "Accessibility label for the reply button")
            button.isEnabled = false
            button.addTarget(self, action: #selector(btnSavePressed), for: .touchUpInside)

            return button
        }()
    }

    /// Creates the `leftBarButtonItem` and the `rightBarButtonItem`
    private func setupNavigationItems() {
        navigationItem.leftBarButtonItem = ({
            let image = UIImage.gridicon(.chevronDown).imageWithTintColor(.listIcon)
            let leftItem = UIBarButtonItem(image: image,
                                           style: .plain,
                                           target: self,
                                           action: #selector(btnExitFullscreenPressed))

            leftItem.accessibilityLabel = NSLocalizedString("Exit Full Screen",
                                                            comment: "Accessibility Label for the exit full screen button on the full screen comment reply mode")
            return leftItem
        })()

        navigationItem.rightBarButtonItem = ({
            let rightItem = UIBarButtonItem(customView: replyButton)

            if let customView = rightItem.customView {
                let iconSize = Parameters.replyButtonIconSize

                customView.widthAnchor.constraint(equalToConstant: iconSize.width).isActive = true
                customView.heightAnchor.constraint(equalToConstant: iconSize.height).isActive = true
            }

            return rightItem
        })()
    }

    /// Changes the `refreshButton` enabled state
    /// - Parameter animated: Whether or not the state change should be animated
    fileprivate func enableRefreshButtonIfNeeded(animated: Bool = true) {
        let whitespaceCharSet = CharacterSet.whitespacesAndNewlines
        let isEnabled = textView.text.trimmingCharacters(in: whitespaceCharSet).isEmpty == false

        if isEnabled == replyButton.isEnabled {
            return
        }

        let setEnabled = {
            self.replyButton.isEnabled = isEnabled
        }

        if animated == false {
            setEnabled()
            return
        }

        UIView.transition(with: replyButton as UIView,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: {
                            setEnabled()
        })
    }

    /// Triggers the `onExitFullscreen` completion handler
    /// - Parameter shouldSave: Whether or not the updated text should trigger a save
    private func exitFullscreen(shouldSave: Bool) {
        guard let completion = onExitFullscreen else {
            return
        }

        let updatedText = textView.text ?? ""

        completion(shouldSave, updatedText)
    }
}
