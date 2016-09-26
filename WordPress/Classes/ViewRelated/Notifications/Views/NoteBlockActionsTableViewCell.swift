import Foundation
import WordPressShared.WPStyleGuide



// MARK: - NoteBlockActionsTableViewCell
//
class NoteBlockActionsTableViewCell: NoteBlockTableViewCell
{
    typealias EventHandler = ((sender: AnyObject) -> Void)

    /// Actions StackView
    ///
    @IBOutlet private var actionsView: UIStackView!

    /// Reply Action Button
    ///
    @IBOutlet private var btnReply: UIButton!

    /// Like Action Button
    ///
    @IBOutlet private var btnLike: UIButton!

    /// Approve Action Button
    ///
    @IBOutlet private var btnApprove: UIButton!

    /// Trash Action Button
    ///
    @IBOutlet private var btnTrash: UIButton!

    /// Spam Action Button
    ///
    @IBOutlet private var btnSpam: UIButton!

    /// Handler to be executed on Reply event
    ///
    var onReplyClick: EventHandler?

    /// Handler to be executed on Like event
    ///
    var onLikeClick: EventHandler?

    /// Handler to be executed on Unlike event
    ///
    var onUnlikeClick: EventHandler?

    /// Handler to be executed on Approve event
    ///
    var onApproveClick: EventHandler?

    /// Handler to be executed on Unapprove event
    ///
    var onUnapproveClick: EventHandler?

    /// Handler to be executed on Trash event
    ///
    var onTrashClick: EventHandler?

    /// Handler to be executed on Spam event
    ///
    var onSpamClick: EventHandler?

    /// Indicates whether the Reply Action is enabled, or not
    ///
    var isReplyEnabled: Bool = false {
        didSet {
            btnReply.hidden = !isReplyEnabled
        }
    }

    /// Indicates whether the Like Action is enabled, or not
    ///
    var isLikeEnabled: Bool = false {
        didSet {
            btnLike.hidden = !isLikeEnabled
        }
    }

    /// Indicates whether the Approve Action is enabled, or not
    ///
    var isApproveEnabled: Bool = false {
        didSet {
            btnApprove.hidden = !isApproveEnabled
        }
    }

    /// Indicates whether the Trash Action is enabled, or not
    ///
    var isTrashEnabled: Bool = false {
        didSet {
            btnTrash.hidden = !isTrashEnabled
        }
    }

    /// Indicates whether the Spam Action is enabled, or not
    ///
    var isSpamEnabled: Bool = false {
        didSet {
            btnSpam.hidden = !isSpamEnabled
        }
    }

    /// Indicates whether Like is in it's "Selected" state, or not
    ///
    var isLikeOn: Bool {
        set {
            btnLike.selected = newValue
            btnLike.accessibilityLabel = likeAccesibilityLabel
            btnLike.accessibilityHint = likeAccessibilityHint
            // Force button trait to avoid automatic "Selected" trait
            btnLike.accessibilityTraits = UIAccessibilityTraitButton
        }
        get {
            return btnLike.selected
        }
    }

    /// Indicates whether Approve is in it's "Selected" state, or not
    ///
    var isApproveOn: Bool {
        set {
            btnApprove.selected = newValue
            btnApprove.accessibilityLabel = approveAccesibilityLabel
            btnApprove.accessibilityHint = approveAccesibilityHint
            // Force button trait to avoid automatic "Selected" trait
            btnApprove.accessibilityTraits = UIAccessibilityTraitButton
        }
        get {
            return btnApprove.selected
        }
    }

    /// Returns the required button spacing
    ///
    private var buttonSpacingForCurrentTraits : CGFloat {
        let isHorizontallyCompact = traitCollection.horizontalSizeClass == .Compact && UIDevice.isPad()
        return isHorizontallyCompact ? Constants.buttonSpacingCompact : Constants.buttonSpacing
    }

    /// Returns the accessibility label for the Approve Button
    ///
    private var approveAccesibilityLabel : String {
        return isApproveOn ? Approve.selectedTitle : Approve.normalTitle
    }

    /// Returns the accessibility hint for the Approve Button
    ///
    private var approveAccesibilityHint : String {
        return isApproveOn ? Approve.selectedHint : Approve.normalHint
    }

    /// Returns the accessibility label for the Like Button
    ///
    private var likeAccesibilityLabel : String {
        return isLikeOn ? Like.selectedTitle : Like.normalTitle
    }

    /// Returns the accessibility hint for the Like Button
    ///
    private var likeAccessibilityHint : String {
        return isLikeOn ? Like.selectedHint : Like.normalHint
    }




    // MARK: - Overriden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .None

        let textNormalColor = WPStyleGuide.Notifications.blockActionDisabledColor
        let textSelectedColor = WPStyleGuide.Notifications.blockActionEnabledColor

        let replyTitle = NSLocalizedString("Reply", comment: "Verb, reply to a comment")
        let spamTitle = NSLocalizedString("Spam", comment: "Verb, spam a comment")
        let trashTitle = NSLocalizedString("Trash", comment: "Move a comment to the trash")

        btnReply.setTitle(replyTitle, forState: .Normal)
        btnReply.setTitleColor(textNormalColor, forState: .Normal)
        btnReply.accessibilityLabel = replyTitle

        btnLike.setTitle(Like.normalTitle, forState: .Normal)
        btnLike.setTitle(Like.selectedTitle, forState: .Highlighted)
        btnLike.setTitle(Like.selectedTitle, forState: .Selected)
        btnLike.setTitleColor(textNormalColor, forState: .Normal)
        btnLike.setTitleColor(textSelectedColor, forState: .Highlighted)
        btnLike.setTitleColor(textSelectedColor, forState: .Selected)
        btnLike.accessibilityLabel = Like.normalTitle

        btnApprove.setTitle(Approve.normalTitle, forState: .Normal)
        btnApprove.setTitle(Approve.selectedTitle, forState: .Highlighted)
        btnApprove.setTitle(Approve.selectedTitle, forState: .Selected)
        btnApprove.setTitleColor(textNormalColor, forState: .Normal)
        btnApprove.setTitleColor(textSelectedColor, forState: .Highlighted)
        btnApprove.setTitleColor(textSelectedColor, forState: .Selected)
        btnApprove.accessibilityLabel = Approve.normalTitle

        btnSpam.setTitle(spamTitle, forState: .Normal)
        btnSpam.setTitleColor(textNormalColor, forState: .Normal)
        btnSpam.accessibilityLabel = spamTitle

        btnTrash.setTitle(trashTitle, forState: .Normal)
        btnTrash.setTitleColor(textNormalColor, forState: .Normal)
        btnTrash.accessibilityLabel = trashTitle
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        actionsView.spacing = buttonSpacingForCurrentTraits
    }



    // MARK: - IBActions
    @IBAction func replyWasPressed(sender: AnyObject) {
        onReplyClick?(sender: sender)
    }

    @IBAction func likeWasPressed(sender: AnyObject) {
        let onClick = isLikeOn ? onUnlikeClick : onLikeClick
        isLikeOn = !isLikeOn

        animateLikeButton(btnLike) {
            onClick?(sender: sender)
        }
    }

    @IBAction func approveWasPressed(sender: AnyObject) {
        let onClick = isApproveOn ? onUnapproveClick : onApproveClick
        isApproveOn = !isApproveOn

        animateApproveButton(btnApprove) {
            onClick?(sender: sender)
        }
    }

    @IBAction func trashWasPressed(sender: AnyObject) {
        onTrashClick?(sender: sender)
    }

    @IBAction func spamWasPressed(sender: AnyObject) {
        onSpamClick?(sender: sender)
    }
}



// MARK: - Animation Helpers
//
private extension NoteBlockActionsTableViewCell
{
    func animateLikeButton(button: UIButton, completion: (() -> Void)) {
        guard let overlayImageView = overlayForButton(button, state: .Selected) else {
            return
        }

        contentView.addSubview(overlayImageView)

        let animation = button.selected ? overlayImageView.fadeInWithRotationAnimation : overlayImageView.fadeOutWithRotationAnimation
        animation { _ in
            overlayImageView.removeFromSuperview()
            completion()
        }
    }

    func animateApproveButton(button: UIButton, completion: (() -> Void)) {
        guard let overlayImageView = overlayForButton(button, state: .Selected) else {
            return
        }

        contentView.addSubview(overlayImageView)

        let animation = button.selected ? overlayImageView.implodeAnimation : overlayImageView.explodeAnimation
        animation { _ in
            overlayImageView.removeFromSuperview()
            completion()
        }
    }

    func overlayForButton(button: UIButton, state: UIControlState) -> UIImageView? {
        guard let buttonImageView = button.imageView, let targetImage = button.imageForState(state) else {
            return nil
        }

        let overlayImageView = UIImageView(image: targetImage)
        overlayImageView.frame = contentView.convertRect(buttonImageView.bounds, fromView: buttonImageView)

        return overlayImageView
    }
}


// MARK: - Private Constants
//
private extension NoteBlockActionsTableViewCell
{
    struct Approve {
        static let normalTitle      = NSLocalizedString("Approve",  comment: "Approve a comment")
        static let selectedTitle    = NSLocalizedString("Approved", comment: "Unapprove a comment")
        static let normalHint       = NSLocalizedString("Approves the comment", comment: "Approves a comment. Spoken Hint.")
        static let selectedHint     = NSLocalizedString("Unapproves the comment", comment: "Unapproves a comment. Spoken Hint.")
    }

    struct Like {
        static let normalTitle      = NSLocalizedString("Like", comment: "Like a comment")
        static let selectedTitle    = NSLocalizedString("Liked", comment: "A comment has been liked")
        static let normalHint       = NSLocalizedString("Likes the comment", comment: "Likes a comment. Spoken Hint.")
        static let selectedHint     = NSLocalizedString("Unlikes the comment", comment: "Unlikes a comment. Spoken Hint.")
    }

    struct Constants {
        static let buttonSpacing = CGFloat(20)
        static let buttonSpacingCompact = CGFloat(10)
    }
}
