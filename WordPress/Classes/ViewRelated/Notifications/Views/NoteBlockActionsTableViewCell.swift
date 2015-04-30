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
            refreshButtonSize(btnReply, isVisible: isReplyEnabled)
            refreshBottomSpacing()
        }
    }
    public var isLikeEnabled: Bool = false {
        didSet {
            refreshButtonSize(btnLike, isVisible: isLikeEnabled)
            refreshBottomSpacing()
        }
    }
    public var isApproveEnabled: Bool = false {
        didSet {
            refreshButtonSize(btnApprove, isVisible: isApproveEnabled)
            refreshBottomSpacing()
        }
    }
    public var isTrashEnabled: Bool = false {
        didSet {
            refreshButtonSize(btnTrash, isVisible: isTrashEnabled)
            refreshBottomSpacing()
        }
    }
    public var isSpamEnabled: Bool = false {
        didSet {
            refreshButtonSize(btnSpam, isVisible: isSpamEnabled)
            refreshBottomSpacing()
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

    // MARK: - Private Methods
    private func hitEventHandler(handler: EventHandler?, sender: AnyObject) {
        if let listener = handler {
            listener(sender: sender)
        }
    }
    
    private func refreshButtonSize(button: UIButton, isVisible: Bool) {
        // When disabled, let's hide the button by shrinking it's width
        let newWidth   = isVisible ? buttonWidth   : CGFloat.min
        let newSpacing = isVisible ? buttonSpacing : CGFloat.min
        
        button.updateConstraint(.Width, constant: newWidth)
        
        actionsView.updateConstraintWithFirstItem(button, attribute: .Trailing, constant: newSpacing)
        actionsView.updateConstraintWithFirstItem(button, attribute: .Leading,  constant: newSpacing)
        
        button.hidden   = !isVisible
        button.enabled  = isVisible
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
    
    // MARK: - Private Constants
    private let buttonWidth                         = CGFloat(55)
    private let buttonSpacing                       = CGFloat(20)
    private let actionsHeight                       = CGFloat(34)
    private let actionsTop                          = CGFloat(11)
    
    // MARK: - IBOutlets
    @IBOutlet private weak var actionsView          : UIView!
    @IBOutlet private weak var btnReply             : UIButton!
    @IBOutlet private weak var btnLike              : UIButton!
    @IBOutlet private weak var btnApprove           : UIButton!
    @IBOutlet private weak var btnTrash             : UIButton!
    @IBOutlet private weak var btnSpam              : UIButton!
}
