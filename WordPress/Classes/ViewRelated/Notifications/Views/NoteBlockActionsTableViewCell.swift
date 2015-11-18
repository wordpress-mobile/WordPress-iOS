import Foundation


@objc public class NoteBlockActionsTableViewCell : NoteBlockTableViewCell
{
    public typealias EventHandler = ((sender: AnyObject) -> Void)

    // MARK: - Public Properties
    public var onReplyClick:        EventHandler?
    public var onLikeClick:         EventHandler?
    public var onUnlikeClick:       EventHandler?
    public var onApproveClick:      EventHandler?
    public var onUnapproveClick:    EventHandler?
    public var onTrashClick:        EventHandler?
    public var onSpamClick:         EventHandler?

    public var isReplyEnabled: Bool = false {
        didSet {
            updateButton(btnReply, enabled: isReplyEnabled)
        }
    }
    public var isLikeEnabled: Bool = false {
        didSet {
            updateButton(btnLike, enabled: isLikeEnabled)
        }
    }
    public var isApproveEnabled: Bool = false {
        didSet {
            updateButton(btnApprove, enabled: isApproveEnabled)
        }
    }
    public var isTrashEnabled: Bool = false {
        didSet {
            updateButton(btnTrash, enabled: isTrashEnabled)
        }
    }
    public var isSpamEnabled: Bool = false {
        didSet {
            updateButton(btnSpam, enabled: isSpamEnabled)
        }
    }
    public var isLikeOn: Bool {
        set {
            btnLike.selected = newValue
        }
        get {
            return btnLike.selected
        }
    }
    public var isApproveOn: Bool {
        set {
            btnApprove.selected = newValue
        }
        get {
            return btnApprove.selected
        }
    }

    
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle              = .None
        
        let textNormalColor         = WPStyleGuide.Notifications.blockActionDisabledColor
        let textSelectedColor       = WPStyleGuide.Notifications.blockActionEnabledColor
        
        let likeNormalTitle         = NSLocalizedString("Like",     comment: "Like a comment")
        let likeSelectedTitle       = NSLocalizedString("Liked",    comment: "A comment has been liked")

        let approveNormalTitle      = NSLocalizedString("Approve",  comment: "Approve a comment")
        let approveSelectedTitle    = NSLocalizedString("Approved", comment: "Unapprove a comment")

        let replyTitle              = NSLocalizedString("Reply",    comment: "Verb, reply to a comment")
        let spamTitle               = NSLocalizedString("Spam",     comment: "Verb, spam a comment")
        let trashTitle              = NSLocalizedString("Trash",    comment: "Move a comment to the trash")

        btnReply.setTitle(replyTitle, forState: .Normal)
        btnReply.setTitleColor(textNormalColor, forState: .Normal)
        btnReply.accessibilityLabel = replyTitle
        
        btnLike.setTitle(likeNormalTitle,           forState: .Normal)
        btnLike.setTitle(likeSelectedTitle,         forState: .Highlighted)
        btnLike.setTitle(likeSelectedTitle,         forState: .Selected)
        btnLike.setTitleColor(textNormalColor,      forState: .Normal)
        btnLike.setTitleColor(textSelectedColor,    forState: .Highlighted)
        btnLike.setTitleColor(textSelectedColor,    forState: .Selected)
        btnLike.accessibilityLabel = likeNormalTitle
        
        btnApprove.setTitle(approveNormalTitle,     forState: .Normal)
        btnApprove.setTitle(approveSelectedTitle,   forState: .Highlighted)
        btnApprove.setTitle(approveSelectedTitle,   forState: .Selected)
        btnApprove.setTitleColor(textNormalColor,   forState: .Normal)
        btnApprove.setTitleColor(textSelectedColor, forState: .Highlighted)
        btnApprove.setTitleColor(textSelectedColor, forState: .Selected)
        btnApprove.accessibilityLabel = approveNormalTitle
        
        btnSpam.setTitle(spamTitle, forState: .Normal)
        btnSpam.setTitleColor(textNormalColor, forState: .Normal)
        btnSpam.accessibilityLabel = spamTitle
        
        btnTrash.setTitle(trashTitle, forState: .Normal)
        btnTrash.setTitleColor(textNormalColor, forState: .Normal)
        btnTrash.accessibilityLabel = trashTitle
    }
    
    public override func updateConstraints() {
        super.updateConstraints()
        
        // Update Button Constraints:  [ Leading - Button ]
        let buttons = [btnReply, btnLike, btnApprove, btnTrash, btnSpam]
        for button in buttons {
            refreshButtonConstraints(button)
        }
        
        // Update the last buttons Trailing constraint
        refreshActionsTrailingConstraint()
        
        // Spacing!
        refreshBottomSpacing()
    }
    
    
    
    // MARK: - IBActions
    @IBAction public func replyWasPressed(sender: AnyObject) {
        hitEventHandler(onReplyClick, sender: sender)
    }
    
    @IBAction public func likeWasPressed(sender: AnyObject) {
        let handler = isLikeOn ? onUnlikeClick : onLikeClick
        hitEventHandler(handler, sender: sender)
        isLikeOn = !isLikeOn
    }
    
    @IBAction public func approveWasPressed(sender: AnyObject) {
        let handler = isApproveOn ? onUnapproveClick : onApproveClick
        hitEventHandler(handler, sender: sender)
        isApproveOn = !isApproveOn
    }
    
    @IBAction public func trashWasPressed(sender: AnyObject) {
        hitEventHandler(onTrashClick, sender: sender)
    }
    
    @IBAction public func spamWasPressed(sender: AnyObject) {
        hitEventHandler(onSpamClick, sender: sender)
    }

    
    
    // MARK: - Event Handlers
    private func hitEventHandler(handler: EventHandler?, sender: AnyObject) {
        if let listener = handler {
            listener(sender: sender)
        }
    }
    

    
    // MARK: - Layout Helpers
    private func updateButton(button: UIButton, enabled: Bool) {
        button.hidden = !enabled
        button.enabled = enabled
        setNeedsUpdateConstraints()
    }
    
    private func refreshButtonConstraints(button: UIButton) {
        let newWidth   = button.hidden ? CGFloat.min : buttonWidth
        let newSpacing = button.hidden ? CGFloat.min : buttonSpacingForCurrentTraits()
        
        // When disabled, let's hide the button by shrinking it's width
        button.updateConstraint(.Width, constant: newWidth)
        
        // Update Leading Constraint
        actionsView.updateConstraintWithFirstItem(button, attribute: .Leading, constant: newSpacing)
    }
    
    private func refreshActionsTrailingConstraint() {
        let newSpacing   = buttonSpacingForCurrentTraits()
        actionsView.updateConstraintWithFirstItem(actionsView, attribute: .Trailing, constant: newSpacing)
    }
    
    private func refreshBottomSpacing() {
        //  Let's remove the bottom space when every action button is disabled
        let hasActions   = isReplyEnabled || isLikeEnabled || isTrashEnabled || isApproveEnabled || isSpamEnabled
        let newTop       = hasActions ? actionsTop    : CGFloat.min
        let newHeight    = hasActions ? actionsHeight : CGFloat.min
        
        contentView.updateConstraintWithFirstItem(actionsView, attribute: .Top, constant: newTop)
        actionsView.updateConstraint(.Height, constant: newHeight)
        actionsView.hidden = !hasActions
        setNeedsLayout()
    }
    
    private func buttonSpacingForCurrentTraits() -> CGFloat {
        let isHorizontallyCompact = traitCollection.horizontalSizeClass == .Compact && UIDevice.isPad()
        return isHorizontallyCompact ? buttonSpacingCompact : buttonSpacing
    }
    
    
    // MARK: - Private Constants
    private let buttonWidth                         = CGFloat(55)
    private let buttonSpacing                       = CGFloat(20)
    private let buttonSpacingCompact                = CGFloat(10)
    private let actionsHeight                       = CGFloat(34)
    private let actionsTop                          = CGFloat(11)
    
    // MARK: - IBOutlets
    @IBOutlet private var actionsView   : UIStackView!
    @IBOutlet private var btnReply      : UIButton!
    @IBOutlet private var btnLike       : UIButton!
    @IBOutlet private var btnApprove    : UIButton!
    @IBOutlet private var btnTrash      : UIButton!
    @IBOutlet private var btnSpam       : UIButton!
}
