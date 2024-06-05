import UIKit

final class CommentDetailReplyTextViewController: NSObject, UIScrollViewDelegate {

    // MARK: - Dependencies

    private unowned var view: UIView

    // MARK: - Properties

    let replyTextView: ReplyTextView

    private lazy var dismissKeyboardTapGesture: UITapGestureRecognizer = {
        UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture(_:))
        )
    }()

    // MARK: - Init

    init(view: UIView, placeholder: String, onReply: ((String) -> Void)? = nil) {
        self.view = view
        self.replyTextView = {
            let replyView = ReplyTextView(width: 0)
            replyView.isHidden = true
            replyView.placeholder = placeholder
            replyView.accessibilityIdentifier = Strings.replyViewAccessibilityId
            replyView.accessibilityHint = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
            replyView.onReply = onReply
            return replyView
        }()
        super.init()
        self.observeKeyboardNotifications()
        self.layout(in: view)
    }

    convenience init(view: UIView, comment: Comment, onReply: ((String) -> Void)? = nil) {
        self.init(view: view, placeholder: Self.placeholder(from: comment), onReply: onReply)
    }

    // MARK: - API

    func showReplyView(in view: UIView) {
        guard !replyTextView.isFirstResponder else {
            return
        }
        self.replyTextView.becomeFirstResponder()
    }

    func update(with comment: Comment) {
        self.replyTextView.placeholder = Self.placeholder(from: comment)
    }
}

// MARK: - Private Helpers

private extension CommentDetailReplyTextViewController {

    // MARK: Layout

    private func layout(in view: UIView) {
        view.addSubview(replyTextView)
        if #available(iOS 17.0, *) {
            view.keyboardLayoutGuide.usesBottomSafeArea = false
        }
        NSLayoutConstraint.activate([
            replyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            replyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            replyTextView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
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
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc func keyboardWillShow(_ note: Foundation.Notification) {
        guard replyTextView.isFirstResponder else {
            return
        }
        self.replyTextView.isHidden = false
        if dismissKeyboardTapGesture.view == nil {
            view.addGestureRecognizer(dismissKeyboardTapGesture)
        }
    }

    @objc func keyboardWillHide(_ note: Foundation.Notification) {
        guard replyTextView.isFirstResponder else {
            return
        }
        let duration = durationFromKeyboardNote(note)
        let curve = curveFromKeyboardNote(note)
        let options = UIView.AnimationOptions(rawValue: UInt(curve.rawValue))
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.replyTextView.frame.origin.y = self.view.frame.maxY
        } completion: { _ in
            self.resetReplyTextView()
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

    // MARK: -

    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        self.replyTextView.resignFirstResponder()
    }

    func resetReplyTextView() {
        self.replyTextView.isHidden = true
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
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
