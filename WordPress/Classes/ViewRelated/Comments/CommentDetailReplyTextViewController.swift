import UIKit

final class CommentDetailReplyTextViewController: NSObject, UIScrollViewDelegate {

    // MARK: - Properties

    let replyTextView: ReplyTextView

    private lazy var dismissKeyboardTapGesture: UITapGestureRecognizer = {
        UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture(_:))
        )
    }()

    private weak var bottomConstraint: NSLayoutConstraint?

    // MARK: - Init

    init(placeholder: String, onReply: ((String) -> Void)? = nil) {
        let replyView = ReplyTextView(width: 0)
        replyView.placeholder = placeholder
        replyView.accessibilityIdentifier = Strings.replyViewAccessibilityId
        replyView.accessibilityHint = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
        replyView.onReply = onReply
        self.replyTextView = replyView
        super.init()
        self.observeKeyboardNotifications()
    }

    convenience init(comment: Comment, onReply: ((String) -> Void)? = nil) {
        self.init(placeholder: Self.placeholder(from: comment), onReply: onReply)
    }

    // MARK: - API

    func showReplyView(in view: UIView) {
        guard !replyTextView.isFirstResponder else {
            return
        }
        self.layout(in: view)
        self.replyTextView.isHidden = true
        self.replyTextView.becomeFirstResponder()
        view.addGestureRecognizer(dismissKeyboardTapGesture)
    }

    func update(with comment: Comment) {
        self.replyTextView.placeholder = Self.placeholder(from: comment)
    }
}

// MARK: - Private Helpers

private extension CommentDetailReplyTextViewController {

    // MARK: Layout

    private func layout(in view: UIView) {
        replyTextView.removeFromSuperview()
        view.addSubview(replyTextView)
        if #available(iOS 17.0, *) {
            view.keyboardLayoutGuide.usesBottomSafeArea = false
        }
        let bottomConstraint: NSLayoutConstraint = {
            if #available(iOS 16.0, *) {
                return replyTextView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
            } else {
                return replyTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            }
        }()
        NSLayoutConstraint.activate([
            replyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            replyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint
        ])
        self.bottomConstraint = bottomConstraint
    }

    // MARK: Keyboard Notifications

    private func observeKeyboardNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(keyboardWillDisappear),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    @objc func keyboardWillShow(_ note: Foundation.Notification) {
        guard replyTextView.isFirstResponder else {
            return
        }
        self.replyTextView.isHidden = false
    }

    @objc func keyboardWillChangeFrame(_ note: Foundation.Notification) {
        guard let view = replyTextView.superview, let bottomConstraint = bottomConstraint, replyTextView.isFirstResponder else {
            return
        }
        let keyboardCoordinateSpace = keyboardCoordinateSpaceFromNote(note) ?? view.window?.window ?? view.coordinateSpace
        let keyboardFrame = keyboardCoordinateSpace.convert(keyboardFrameEndFromNote(note), to: view.coordinateSpace)
        print("WILL CHANGE FRAME TO: \(keyboardFrame)")
    }

    @objc func keyboardWillDisappear() {
        guard let view = replyTextView.superview, replyTextView.isFirstResponder else {
            return
        }
    }

    @objc func keyboardDidHide(_ note: Foundation.Notification) {
        guard !replyTextView.isFirstResponder, replyTextView.window != nil else {
            return
        }
        let duration = durationFromKeyboardNote(note)
        let curve = curveFromKeyboardNote(note)
        let options = UIView.AnimationOptions(rawValue: UInt(curve.rawValue))
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.replyTextView.frame.origin.y += self.replyTextView.bounds.height
        } completion: { _ in
            self.removeReplyTextView()

        }
    }

    func durationFromKeyboardNote(_ note: Foundation.Notification) -> TimeInterval {
        guard let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return TimeInterval(0)
        }
        return duration
    }

    func curveFromKeyboardNote(_ note: Foundation.Notification) -> UIView.AnimationCurve {
        guard let rawCurve = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIView.AnimationCurve(rawValue: rawCurve) else {
            return .easeInOut
        }
        return curve
    }

    func keyboardFrameEndFromNote(_ note: Foundation.Notification) -> CGRect {
        return note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
    }

    func keyboardCoordinateSpaceFromNote(_ note: Foundation.Notification) -> UICoordinateSpace? {
        return (note.object as? UIScreen)?.coordinateSpace
    }

    // MARK: -

    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        self.replyTextView.resignFirstResponder()
    }

    func removeReplyTextView() {
        self.replyTextView.removeFromSuperview()
        if let view = dismissKeyboardTapGesture.view {
            view.removeGestureRecognizer(dismissKeyboardTapGesture)
        }
    }

    static func placeholder(from comment: Comment) -> String {
        String(format: Strings.replyPlaceholderFormat, comment.authorForDisplay())
    }

    enum Strings {
        static let replyPlaceholderFormat = NSLocalizedString(
            "Reply to %1$@",
            comment: "Placeholder text for the reply text field."
            + "%1$@ is a placeholder for the comment author."
            + "Example: Reply to Pamela Nguyen"
        )
        static let replyViewAccessibilityId = "reply-comment-view"
    }
}
