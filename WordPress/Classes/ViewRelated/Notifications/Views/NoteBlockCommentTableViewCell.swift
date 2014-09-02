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

    public var attributedCommentText: NSAttributedString? {
        didSet {
            refreshInterfaceStyle()
        }
    }
    public var name: String? {
        didSet {
            nameLabel.text  = name != nil ? name! : String()
        }
    }
    public var timestamp: String? {
        didSet {
            timestampLabel.text  = timestamp != nil ? timestamp! : String()
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
    public var isMoreEnabled: Bool = false {
        didSet {
            refreshButtonSize(btnMore, isVisible: isMoreEnabled)
            refreshBottomSpacing()
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
            refreshInterfaceStyle()
        }
    }

    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
        
        let success = { (image: UIImage) in
            self.gravatarImageView.displayImageWithFadeInAnimation(image)
        }
        
        gravatarImageView.downloadImage(url, placeholderName: placeholderName, success: success, failure: nil)
        
        gravatarURL = url
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Labels
        nameLabel.font                      = WPStyleGuide.Notifications.blockBoldFont
        timestampLabel.font                 = WPStyleGuide.Notifications.blockRegularFont
        
        // Background
        approvalStatusView.backgroundColor  = WPStyleGuide.Notifications.blockUnapprovedBgColor
        approvalSidebarView.backgroundColor = WPStyleGuide.Notifications.blockUnapprovedSideColor
        
        // Separator Line should be 1px: Handle Retina!
        let separatorHeightInPixels         = separatorHeight / UIScreen.mainScreen().scale
        separatorView.updateConstraint(.Height, constant: separatorHeightInPixels)
        
        // Setup Action Buttons
        let textNormalColor                 = WPStyleGuide.Notifications.blockActionDisabledColor
        let textSelectedColor               = WPStyleGuide.Notifications.blockActionEnabledColor
        
        let likeNormalTitle                 = NSLocalizedString("Like", comment: "Like a comment")
        let likeSelectedTitle               = NSLocalizedString("Liked", comment: "A comment has been liked")

        let approveNormalTitle              = NSLocalizedString("Approve", comment: "Approve a comment")
        let approveSelectedTitle            = NSLocalizedString("Approved", comment: "Unapprove a comment")
        
        let moreTitle                       = NSLocalizedString("More",  comment: "Verb, display More actions for a comment")
        let trashTitle                      = NSLocalizedString("Trash", comment: "Move a comment to the trash")
        
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
        let handler = isApproveOn ? onUnapproveClick : onApproveClick
        hitEventHandler(handler)
        isApproveOn = !isApproveOn
    }
    
    @IBAction public func trashWasPressed(sender: AnyObject) {
        hitEventHandler(onTrashClick)
    }
    
    @IBAction public func moreWasPressed(sender: AnyObject) {
        hitEventHandler(onMoreClick)
    }
    
    
    // MARK: - Private Methods
    private func hitEventHandler(handler: EventHandler?) {
        if let listener = handler {
            listener()
        }
    }
    
    private func refreshButtonSize(button: UIButton, isVisible: Bool) {
        // When disabled, let's hide the button by shrinking it's width
        let width    : CGFloat  = isVisible ? buttonWidth     : CGFloat.min
        let trailing : CGFloat  = isVisible ? buttonTrailing  : CGFloat.min
        
        button.updateConstraint(.Width, constant: width)
        
        contentView.updateConstraintForView(button, attribute: .Trailing, constant: trailing)
        contentView.updateConstraintForView(button, attribute: .Leading,  constant: trailing)
        
        button.hidden   = !isVisible
        button.enabled  = isVisible
    }

    private func refreshBottomSpacing() {
        //  Note:
        //  When all of the buttons are disabled, let's remove the bottom space.
        //  Every button is linked to btnMore: We can do this in just one shot!
        //
        let hasButtonsEnabled   = isLikeEnabled || isTrashEnabled || isApproveEnabled || isMoreEnabled
        let moreTop             = hasButtonsEnabled ? buttonTop     : CGFloat.min
        let moreHeight          = hasButtonsEnabled ? buttonHeight  : CGFloat.min
        
        contentView.updateConstraintForView(btnMore, attribute: .Top, constant: moreTop)
        btnMore.updateConstraint(.Height, constant: moreHeight)
        setNeedsLayout()
    }
    
    private func refreshInterfaceStyle() {
        // If Approval is not even enabled, let's consider this as approved!
        let isCommentApproved               = isApproveOn || !isApproveEnabled
        approvalStatusView.hidden           = isCommentApproved
        separatorView.backgroundColor       = WPStyleGuide.Notifications.blockSeparatorColorForComment(isApproved: isCommentApproved)
        nameLabel.textColor                 = WPStyleGuide.Notifications.blockTextColorForComment(isApproved: isCommentApproved)
        timestampLabel.textColor            = WPStyleGuide.Notifications.blockTimestampColorForComment(isApproved: isCommentApproved)
        super.attributedText                = isCommentApproved ? attributedCommentApprovedText : attributedCommentUnapprovedText
    }
    
    
    // MARK: - Private Calculated Properties
    private var attributedCommentApprovedText : NSAttributedString? {
        if attributedCommentText == nil {
            return nil
        }
            
        let unwrappedMutableString  = attributedCommentText!.mutableCopy() as NSMutableAttributedString
        let range                   = NSRange(location: 0, length: min(1, unwrappedMutableString.length))
        let paragraph               = WPStyleGuide.Notifications.blockParagraphStyleWithIndentation(firstLineHeadIndent)
        unwrappedMutableString.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
        
        return unwrappedMutableString
    }

    private var attributedCommentUnapprovedText : NSAttributedString? {
        let text = attributedCommentApprovedText
        if text == nil {
            return nil
        }
            
        let unwrappedMutableString  = text!.mutableCopy() as NSMutableAttributedString
        let range                   = NSRange(location: 0, length: unwrappedMutableString.length)
        let textColor               = WPStyleGuide.Notifications.blockUnapprovedTextColor
        unwrappedMutableString.addAttribute(NSForegroundColorAttributeName, value: textColor, range: range)

        return unwrappedMutableString
    }

    // MARK: - Private Constants
    private let separatorHeight                     : CGFloat   = 1
    private let buttonWidth                         : CGFloat   = 55
    private let buttonHeight                        : CGFloat   = 30
    private let buttonTop                           : CGFloat   = 20
    private let buttonTrailing                      : CGFloat   = 20
    private let firstLineHeadIndent                 : CGFloat   = 43
    private let placeholderName                     : String    = "gravatar"
    
    // MARK: - Private Properties
    private var gravatarURL                         : NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var approvalStatusView   : UIView!
    @IBOutlet private weak var approvalSidebarView  : UIView!
    @IBOutlet private weak var gravatarImageView    : UIImageView!
    @IBOutlet private weak var nameLabel            : UILabel!
    @IBOutlet private weak var timestampLabel       : UILabel!
    @IBOutlet private weak var separatorView        : UIView!
    @IBOutlet private weak var btnLike              : UIButton!
    @IBOutlet private weak var btnApprove           : UIButton!
    @IBOutlet private weak var btnTrash             : UIButton!
    @IBOutlet private weak var btnMore              : UIButton!
}
