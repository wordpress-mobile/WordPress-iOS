import Foundation


@objc public class NoteBlockCommentTableViewCell : NoteBlockTextTableViewCell
{
    public typealias EventHandler = (() -> Void)

    // MARK: - Public Properties
    public var onLikeClick:         EventHandler?
    public var onUnlikeClick:       EventHandler?
    public var onApproveClick:      EventHandler?
    public var onUnapproveClick:    EventHandler?
    public var onTrashClick:        EventHandler?
    public var onMoreClick:         EventHandler?

    public var isLikeEnabled: Bool = false {
        didSet {
            setupButtonConstraints(btnLike, enabled: isLikeEnabled)
        }
    }
    public var isApproveEnabled: Bool = false {
        didSet {
            setupButtonConstraints(btnApprove, enabled: isApproveEnabled)
        }
    }
    public var isTrashEnabled: Bool = false {
        didSet {
            setupButtonConstraints(btnTrash, enabled: isTrashEnabled)
        }
    }
    public var isMoreEnabled: Bool = false {
        didSet {
            setupButtonConstraints(btnMore, enabled: isMoreEnabled)
        }
    }
    public var isLikeOn: Bool = false {
        didSet {
            btnLike.selected = isLikeOn
        }
    }
    public var isApproveOn: Bool = false {
        didSet {
            btnApprove.selected = isApproveOn
        }
    }

    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        let textNormalColor         = Notification.Colors.actionOffText
        let textSelectedColor       = Notification.Colors.actionOnText
        
        let likeNormalTitle         = NSLocalizedString("Like", comment: "Like a comment")
        let likeSelectedTitle       = NSLocalizedString("Liked", comment: "A comment has been liked")

        let approveNormalTitle      = NSLocalizedString("Approve", comment: "Approve a comment")
        let approveSelectedTitle    = NSLocalizedString("Approved", comment: "Unapprove a comment")
        
        let moreTitle               = NSLocalizedString("More",  comment: "Verb, display More actions for a comment")
        let trashTitle              = NSLocalizedString("Trash", comment: "Move a comment to the trash")
        
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
        
        btnMore.setTitle(moreTitle, forState: .Normal)
        btnMore.setTitleColor(textNormalColor, forState: .Normal)
        btnMore.accessibilityLabel = moreTitle
        
        btnTrash.setTitle(trashTitle, forState: .Normal)
        btnTrash.setTitleColor(textNormalColor, forState: .Normal)
        btnTrash.accessibilityLabel = trashTitle
    }
    
    // MARK: - IBActions
    @IBAction public func likeWasPressed(sender: AnyObject) {
        let handler = isLikeOn ? onUnlikeClick : onLikeClick
        hitEventHandler(handler)
        isLikeOn = !isLikeOn
    }
    
    @IBAction public func approveWasPressed(sender: AnyObject) {
        let handler = isLikeOn ? onUnapproveClick : onApproveClick
        hitEventHandler(handler)
        isApproveOn = !isApproveOn
    }
    
    @IBAction public func trashWasPressed(sender: AnyObject) {
        hitEventHandler(onTrashClick)
    }
    
    @IBAction public func moreWasPressed(sender: AnyObject) {
        hitEventHandler(onMoreClick)
    }
    
    
    // MARK: - Private
    private func hitEventHandler(handler: EventHandler?) {
        if let listener = handler {
            listener()
        }
    }
    
    private func setupButtonConstraints(button: UIButton, enabled: Bool) {
        let width: CGFloat       = hidden ? CGFloat.min : buttonWidth
        let trailing: CGFloat    = hidden ? CGFloat.min : buttonTrailing
        
        for constraint in button.constraints() as [NSLayoutConstraint] {
            if constraint.firstAttribute == NSLayoutAttribute.Width {
                constraint.constant = width
            }
        }
        
        for constraint in contentView.constraints() as [NSLayoutConstraint] {
            if constraint.firstItem as NSObject == button && constraint.firstAttribute == NSLayoutAttribute.Trailing {
                constraint.constant = trailing
            }
        }
        
        button.hidden   = !enabled
        button.enabled  = enabled
    }
    
    // MARK: - Constants
    private let buttonWidth:    CGFloat = 55
    private let buttonTrailing: CGFloat = 20
    
    // MARK: - IBOutlets
    @IBOutlet private weak var btnLike      : UIButton!
    @IBOutlet private weak var btnApprove   : UIButton!
    @IBOutlet private weak var btnTrash     : UIButton!
    @IBOutlet private weak var btnMore      : UIButton!
}
