import Foundation
import WordPressShared.WPStyleGuide



// MARK: - NoteBlockActionsTableViewCell
//
class NoteBlockActionsTableViewCell: NoteBlockTableViewCell {
    typealias EventHandler = ((_ sender: AnyObject) -> Void)

    /// Actions StackView
    ///
    @IBOutlet fileprivate var actionsView: UIStackView!

    /// Reply Action Button
    ///
    @IBOutlet fileprivate var btnReply: UIButton!

    /// Like Action Button
    ///
    @IBOutlet fileprivate var btnLike: UIButton!

    /// Approve Action Button
    ///
    @IBOutlet fileprivate var btnApprove: UIButton!

    /// Trash Action Button
    ///
    @IBOutlet fileprivate var btnTrash: UIButton!

    /// Spam Action Button
    ///
    @IBOutlet fileprivate var btnSpam: UIButton!

    /// Edit Action Button
    ///
    @IBOutlet fileprivate var btnEdit: UIButton!

    /// Handler to be executed on Reply event
    ///
    @objc var onReplyClick: EventHandler?

    /// Handler to be executed on Like event
    ///
    @objc var onLikeClick: EventHandler?

    /// Handler to be executed on Unlike event
    ///
    @objc var onUnlikeClick: EventHandler?

    /// Handler to be executed on Approve event
    ///
    @objc var onApproveClick: EventHandler?

    /// Handler to be executed on Unapprove event
    ///
    @objc var onUnapproveClick: EventHandler?

    /// Handler to be executed on Trash event
    ///
    @objc var onTrashClick: EventHandler?

    /// Handler to be executed on Spam event
    ///
    @objc var onSpamClick: EventHandler?

    // Handler to be executed on Edition event
    //
    @objc var onEditClick: EventHandler?

    /// Indicates whether the Reply Action is enabled, or not
    ///
    @objc var isReplyEnabled: Bool = false {
        didSet {
            toggleAction(button: btnReply, hidden: !isReplyEnabled)
        }
    }

    /// Indicates whether the Like Action is enabled, or not
    ///
    @objc var isLikeEnabled: Bool = false {
        didSet {
            toggleAction(button: btnLike, hidden: !isLikeEnabled)
        }
    }

    /// Indicates whether the Approve Action is enabled, or not
    ///
    @objc var isApproveEnabled: Bool = false {
        didSet {
            toggleAction(button: btnApprove, hidden: !isApproveEnabled)
        }
    }

    /// Indicates whether the Trash Action is enabled, or not
    ///
    @objc var isTrashEnabled: Bool = false {
        didSet {
            toggleAction(button: btnTrash, hidden: !isTrashEnabled)
        }
    }

    /// Indicates whether the Spam Action is enabled, or not
    ///
    @objc var isSpamEnabled: Bool = false {
        didSet {
            toggleAction(button: btnSpam, hidden: !isSpamEnabled)
        }
    }

    /// Indicates whether the Edit Action is enabled, or not
    ///
    @objc var isEditEnabled: Bool = false {
        didSet {
            toggleAction(button: btnEdit, hidden: !isEditEnabled)
        }
    }

    /// Indicates whether Like is in it's "Selected" state, or not
    ///
    @objc var isLikeOn: Bool {
        set {
            btnLike.isSelected = newValue
            btnLike.accessibilityLabel = likeAccesibilityLabel
            btnLike.accessibilityHint = likeAccessibilityHint
            // Force button trait to avoid automatic "Selected" trait
            btnLike.accessibilityTraits = UIAccessibilityTraitButton
        }
        get {
            return btnLike.isSelected
        }
    }

    /// Indicates whether Approve is in it's "Selected" state, or not
    ///
    @objc var isApproveOn: Bool {
        set {
            btnApprove.isSelected = newValue
            btnApprove.accessibilityLabel = approveAccesibilityLabel
            btnApprove.accessibilityHint = approveAccesibilityHint
            // Force button trait to avoid automatic "Selected" trait
            btnApprove.accessibilityTraits = UIAccessibilityTraitButton
        }
        get {
            return btnApprove.isSelected
        }
    }

    /// Returns the required button spacing
    ///
    fileprivate var buttonSpacingForCurrentTraits: CGFloat {
        let isHorizontallyCompact = traitCollection.horizontalSizeClass == .compact
        return isHorizontallyCompact ? Constants.buttonSpacingCompact : Constants.buttonSpacing
    }

    /// Returns the accessibility label for the Approve Button
    ///
    fileprivate var approveAccesibilityLabel: String {
        return isApproveOn ? Approve.selectedTitle : Approve.normalTitle
    }

    /// Returns the accessibility hint for the Approve Button
    ///
    fileprivate var approveAccesibilityHint: String {
        return isApproveOn ? Approve.selectedHint : Approve.normalHint
    }

    /// Returns the accessibility label for the Like Button
    ///
    fileprivate var likeAccesibilityLabel: String {
        return isLikeOn ? Like.selectedTitle : Like.normalTitle
    }

    /// Returns the accessibility hint for the Like Button
    ///
    fileprivate var likeAccessibilityHint: String {
        return isLikeOn ? Like.selectedHint : Like.normalHint
    }




    // MARK: - Overriden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        let textNormalColor = WPStyleGuide.Notifications.blockActionDisabledColor
        let textSelectedColor = WPStyleGuide.Notifications.blockActionEnabledColor

        btnReply.setTitle(Reply.normalTitle, for: UIControlState())
        btnReply.setTitleColor(textNormalColor, for: UIControlState())

        btnLike.setTitle(Like.normalTitle, for: UIControlState())
        btnLike.setTitle(Like.selectedTitle, for: .highlighted)
        btnLike.setTitle(Like.selectedTitle, for: .selected)
        btnLike.setTitleColor(textNormalColor, for: UIControlState())
        btnLike.setTitleColor(textSelectedColor, for: .highlighted)
        btnLike.setTitleColor(textSelectedColor, for: .selected)

        btnApprove.setTitle(Approve.normalTitle, for: UIControlState())
        btnApprove.setTitle(Approve.selectedTitle, for: .highlighted)
        btnApprove.setTitle(Approve.selectedTitle, for: .selected)
        btnApprove.setTitleColor(textNormalColor, for: UIControlState())
        btnApprove.setTitleColor(textSelectedColor, for: .highlighted)
        btnApprove.setTitleColor(textSelectedColor, for: .selected)

        btnEdit.setTitleColor(textNormalColor, for: UIControlState())

        btnSpam.setTitle(MarkAsSpam.title, for: .normal)
        btnSpam.setTitleColor(textNormalColor, for: UIControlState())
        btnSpam.accessibilityLabel = MarkAsSpam.title
        btnSpam.accessibilityHint = MarkAsSpam.hint

        btnTrash.setTitleColor(textNormalColor, for: UIControlState())
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        actionsView.spacing = buttonSpacingForCurrentTraits
    }



    // MARK: - IBActions
    @IBAction func replyWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            onReplyClick?(sender)
        }
    }

    @IBAction func likeWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            let onClick = isLikeOn ? onUnlikeClick : onLikeClick
            isLikeOn = !isLikeOn

            if isLikeOn {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            animateLikeButton(btnLike) {
                onClick?(sender)
            }
        }
    }

    @IBAction func approveWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            let onClick = isApproveOn ? onUnapproveClick : onApproveClick
            isApproveOn = !isApproveOn

            if isApproveOn {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            animateApproveButton(btnApprove) {
                onClick?(sender)
            }
        }
    }

    @IBAction func trashWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            onTrashClick?(sender)
        }
    }

    @IBAction func spamWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            onSpamClick?(sender)
        }
    }

    @IBAction func editWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            onEditClick?(sender)
        }
    }
}



// MARK: - Action Button Helpers
//
private extension NoteBlockActionsTableViewCell {

    func toggleAction(button: UIButton, hidden: Bool) {
        button.isHidden = hidden
        /*
         * Since these buttons are in a stackView, and since they are
         * subclasses of `VerticallyStackedButton`, we need to zero the alpha of the button.
         * This keeps the custom layout in `VerticallyStackedButton` from breaking out
         * of the constraint-based layout the stackView sets on the button, once hidden.
         * Note: ideally, we wouldn't be doing custom layout in `VerticallyStackedButton`.
         * - Brent Feb 15/2017
         */
        button.alpha = hidden ? 0.0 : 1.0
    }

    func animateLikeButton(_ button: UIButton, completion: @escaping (() -> Void)) {
        guard let overlayImageView = overlayForButton(button, state: .selected) else {
            return
        }

        contentView.addSubview(overlayImageView)

        let animation = button.isSelected ? overlayImageView.fadeInWithRotationAnimation : overlayImageView.fadeOutWithRotationAnimation
        animation { _ in
            overlayImageView.removeFromSuperview()
            completion()
        }
    }

    func animateApproveButton(_ button: UIButton, completion: @escaping (() -> Void)) {
        guard let overlayImageView = overlayForButton(button, state: .selected) else {
            return
        }

        contentView.addSubview(overlayImageView)

        let animation = button.isSelected ? overlayImageView.implodeAnimation : overlayImageView.explodeAnimation
        animation { _ in
            overlayImageView.removeFromSuperview()
            completion()
        }
    }

    func overlayForButton(_ button: UIButton, state: UIControlState) -> UIImageView? {
        guard let buttonImageView = button.imageView, let targetImage = button.image(for: state) else {
            return nil
        }

        let overlayImageView = UIImageView(image: targetImage)
        overlayImageView.frame = contentView.convert(buttonImageView.bounds, from: buttonImageView)

        return overlayImageView
    }
}


// MARK: - Private Constants
//
private extension NoteBlockActionsTableViewCell {
    struct Approve {
        static let normalTitle      = NSLocalizedString("Approve", comment: "Approve a comment")
        static let selectedTitle    = NSLocalizedString("Approved", comment: "Unapprove a comment")
        static let normalHint       = NSLocalizedString("Approves the comment", comment: "Approves a comment. Spoken Hint.")
        static let selectedHint     = NSLocalizedString("Unapproves the comment", comment: "Unapproves a comment. Spoken Hint.")
    }

    struct Edit {
        static let normalTitle      = NSLocalizedString("Edit", comment: "Verb, edit a comment")
        static let normalHint       = NSLocalizedString("Edits a comment", comment: "Edit Action Spoken hint.")
    }

    struct Like {
        static let normalTitle      = NSLocalizedString("Like", comment: "Like a comment")
        static let selectedTitle    = NSLocalizedString("Liked", comment: "A comment has been liked")
        static let normalHint       = NSLocalizedString("Likes the comment", comment: "Likes a comment. Spoken Hint.")
        static let selectedHint     = NSLocalizedString("Unlikes the comment", comment: "Unlikes a comment. Spoken Hint.")
    }

    struct Reply {
        static let normalTitle      = NSLocalizedString("Reply", comment: "Verb, reply to a comment")
        static let normalHint       = NSLocalizedString("Replies to a comment", comment: "Reply Action Spoken hint.")
    }

    struct Trash {
        static let normalTitle      = NSLocalizedString("Trash", comment: "Move a comment to the trash")
        static let normalHint       = NSLocalizedString("Moves the comment to Trash", comment: "Trash Action Spoken hint")
    }

    struct Constants {
        static let buttonSpacing = CGFloat(20)
        static let buttonSpacingCompact = CGFloat(9)
    }
}
