import UIKit

final class CommentDetailReplyTextViewController: NSObject, UIScrollViewDelegate {

    // MARK: - Dependencies

    private unowned var view: UIView

    private let moderationViewModel: CommentModerationViewModel

    // MARK: - Properties

    let replyTextView: NewReplyTextView

    private lazy var dismissKeyboardTapGesture: UITapGestureRecognizer = {
        UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture(_:))
        )
    }()

    // MARK: - Init

    init(
        view: UIView,
        moderationViewModel: CommentModerationViewModel,
        placeholder: String,
        onReply: ((String) -> Void)? = nil
    ) {
        self.view = view
        self.moderationViewModel = moderationViewModel
        self.replyTextView = {
            let replyView = NewReplyTextView()
            replyView.isHidden = true
            replyView.placeholder = placeholder
            replyView.accessibilityIdentifier = Strings.replyViewAccessibilityId
            replyView.accessibilityHint = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
            return replyView
        }()
        super.init()
        self.observeKeyboardNotifications()
        self.layout(in: view)
    }

    convenience init(
        view: UIView,
        moderationViewModel: CommentModerationViewModel,
        comment: Comment,
        onReply: ((String) -> Void)? = nil
    ) {
        self.init(
            view: view,
            moderationViewModel: moderationViewModel,
            placeholder: Self.placeholder(from: comment),
            onReply: onReply
        )
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

// MARK: - Keyboard Notifications

private extension CommentDetailReplyTextViewController {

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
        nc.addObserver(
            self,
            selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    var moderationReplyTextView: NewReplyTextView {
        return self.moderationViewModel.textView
    }

    var keyboardReplyTextView: NewReplyTextView {
        return self.replyTextView
    }

    @objc func keyboardWillShow(_ note: Foundation.Notification) {
        self.refreshReplyTextView(keyboardFrame: note.keyboardFrameEnd)
    }

    @objc func keyboardWillHide(_ note: Foundation.Notification) {
        // Ensure the `replyTextView` hides along with the keyboard, regardless of its first responder status.
        guard !self.replyTextView.isHidden else {
            return
        }
        let duration = self.durationFromKeyboardNote(note)
        let curve = self.curveFromKeyboardNote(note)
        let options = UIView.AnimationOptions(rawValue: UInt(curve.rawValue))
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.replyTextView.frame.origin.y = self.view.frame.maxY
        }
    }

    @objc func keyboardDidHide(_ note: Foundation.Notification) {
        DispatchQueue.main.async {
            self.refreshReplyTextView(keyboardFrame: self.view.keyboardLayoutGuide.layoutFrame)
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
}

// MARK: - Private Helpers

private extension CommentDetailReplyTextViewController {

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

    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        self.moderationReplyTextView.resignFirstResponder()
        self.replyTextView.resignFirstResponder()
    }

    func refreshReplyTextView(keyboardFrame: CGRect) {
        let isKeyboardCoversModerationReplyView: Bool = moderationReplyTextView.convert(moderationReplyTextView.bounds, to: view).intersects(keyboardFrame)

        if isKeyboardCoversModerationReplyView && moderationReplyTextView.isFirstResponder {
            replyTextView.becomeFirstResponder()
        } else if !isKeyboardCoversModerationReplyView && replyTextView.isFirstResponder {
            moderationReplyTextView.becomeFirstResponder()
        }

        self.replyTextView.isHidden = !replyTextView.isFirstResponder
        self.replyTextView.sizeToFit()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        if let view = dismissKeyboardTapGesture.view {
            view.removeGestureRecognizer(dismissKeyboardTapGesture)
        }
        if replyTextView.isFirstResponder || moderationReplyTextView.isFirstResponder {
            self.view.addGestureRecognizer(dismissKeyboardTapGesture)
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

// MARK: - Extensions

private extension Foundation.Notification {
    var keyboardFrameEnd: CGRect {
        return userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
    }
}
