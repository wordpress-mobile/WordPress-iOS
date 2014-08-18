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
            btnLike.enabled = isLikeEnabled
        }
    }
    public var isApproveEnabled: Bool = false {
        didSet {
            btnApprove.enabled = isApproveEnabled
        }
    }
    public var isTrashEnabled: Bool = false {
        didSet {
            btnTrash.enabled = isTrashEnabled
        }
    }
    public var isMoreEnabled: Bool = false {
        didSet {
            btnMore.enabled = isMoreEnabled
        }
    }
    public var isLikeOn: Bool = false {
        didSet {
            let textColor = isLikeOn ? Notification.Colors.actionOnText : Notification.Colors.actionOffText
            let likeTitle = isLikeOn ? NSLocalizedString("Liked", comment: "A comment has been liked") :
                NSLocalizedString("Like", comment: "Like a comment")
            
            btnLike.selected = isLikeOn
            btnLike.accessibilityLabel = likeTitle
            
            btnLike.setTitle(likeTitle, forState: .Normal)
            btnLike.setTitleColor(textColor, forState: .Normal)
        }
    }
    public var isApproveOn: Bool = false {
        didSet {
            let textColor    = isApproveOn ? Notification.Colors.actionOnText : Notification.Colors.actionOffText
            let approveTitle = isApproveOn ? NSLocalizedString("Approved", comment: "Unapprove a comment") :
                NSLocalizedString("Approve", comment: "Approve a comment")
            
            btnApprove.selected = isApproveOn
            btnApprove.accessibilityLabel = approveTitle
            
            btnApprove.setTitle(approveTitle, forState: .Normal)
            btnApprove.setTitleColor(textColor, forState: .Normal)
        }
    }
    

    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        let textColor   = Notification.Colors.actionOffText
        let moreTitle   = NSLocalizedString("More",  comment: "Verb, display More actions for a comment")
        let trashTitle  = NSLocalizedString("Trash", comment: "Move a comment to the trash")
        
        btnMore.setTitle(moreTitle, forState: .Normal)
        btnMore.setTitleColor(textColor, forState: .Normal)
        btnMore.accessibilityLabel = moreTitle
        
        btnTrash.setTitle(trashTitle, forState: .Normal)
        btnTrash.setTitleColor(textColor, forState: .Normal)
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
    
    private func hitEventHandler(handler: EventHandler?) {
        if let listener = handler {
            listener()
        }
    }
    
    // MARK: - IBOutlets
    @IBOutlet private weak var btnLike      : UIButton!
    @IBOutlet private weak var btnApprove   : UIButton!
    @IBOutlet private weak var btnTrash     : UIButton!
    @IBOutlet private weak var btnMore      : UIButton!
}
