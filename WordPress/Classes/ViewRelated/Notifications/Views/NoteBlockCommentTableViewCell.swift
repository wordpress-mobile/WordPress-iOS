import Foundation


@objc public class NoteBlockCommentTableViewCell : NoteBlockTextTableViewCell
{
    public typealias EventHandler = (() -> Void)

    // MARK: - Public Properties
    public var onLikeClick:     EventHandler?
    public var onUnlikeClick:   EventHandler?
    public var onSpamClick:     EventHandler?
    public var onTrashClick:    EventHandler?
    public var onMoreClick:     EventHandler?

    public var isLikeEnabled: Bool = false {
        didSet {
            btnLike.enabled = isLikeEnabled
        }
    }
    public var isSpamEnabled: Bool = false {
        didSet {
            btnSpam.enabled = isSpamEnabled
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
            let likeTitle = isLikeOn ? NSLocalizedString("Unlike", comment: "Unlike a comment") :
                NSLocalizedString("Like", comment: "Like a comment")
            
            btnLike.setTitle(likeTitle, forState: .Normal)
            btnLike.accessibilityLabel = likeTitle
        }
    }

    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        let textColor   = Notification.Colors.actionText
        let moreTitle   = NSLocalizedString("More",  comment: "Verb, display More actions for a comment")
        let trashTitle  = NSLocalizedString("Trash", comment: "Move a comment to the trash")
        let spamTitle   = NSLocalizedString("Spam",  comment: "Verb, mark a comment as spam")
        
        btnLike.setTitleColor(textColor, forState: .Normal)
        
        btnMore.setTitle(moreTitle, forState: .Normal)
        btnMore.setTitleColor(textColor, forState: .Normal)
        btnMore.accessibilityLabel = moreTitle
        
        btnTrash.setTitle(trashTitle, forState: .Normal)
        btnTrash.setTitleColor(textColor, forState: .Normal)
        btnTrash.accessibilityLabel = trashTitle
        
        btnSpam.setTitle(spamTitle, forState: .Normal)
        btnSpam.setTitleColor(textColor, forState: .Normal)
        btnSpam.accessibilityLabel = spamTitle
    }
    
    // MARK: - IBActions
    @IBAction public func likeWasPressed(sender: AnyObject) {
        let handler = isLikeOn ? onUnlikeClick : onLikeClick
        hitEventHandler(handler)
        isLikeOn = !isLikeOn
    }
    
    @IBAction public func spamWasPressed(sender: AnyObject) {
        hitEventHandler(onSpamClick)
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
    @IBOutlet private weak var btnLike  : UIButton!
    @IBOutlet private weak var btnSpam  : UIButton!
    @IBOutlet private weak var btnTrash : UIButton!
    @IBOutlet private weak var btnMore  : UIButton!
}
