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

    public override var attributedText: NSAttributedString? {
        didSet {
            super.attributedText = applyIndentation(attributedText)
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
            setupButtonConstraints(btnLike, enabled: isLikeEnabled)
            updateBottomSpacingIfNeeded()
        }
    }
    public var isApproveEnabled: Bool = false {
        didSet {
            setupButtonConstraints(btnApprove, enabled: isApproveEnabled)
            updateBottomSpacingIfNeeded()
        }
    }
    public var isTrashEnabled: Bool = false {
        didSet {
            setupButtonConstraints(btnTrash, enabled: isTrashEnabled)
            updateBottomSpacingIfNeeded()
        }
    }
    public var isMoreEnabled: Bool = false {
        didSet {
            setupButtonConstraints(btnMore, enabled: isMoreEnabled)
            updateBottomSpacingIfNeeded()
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
        nameLabel.font                  = WPStyleGuide.Notifications.blockBoldFont
        nameLabel.textColor             = WPStyleGuide.Notifications.blockTextColor
        timestampLabel.font             = WPStyleGuide.Notifications.blockRegularFont
        timestampLabel.textColor        = WPStyleGuide.Notifications.blockQuotedColor
        
        let separatorHeightInPixels = separatorHeight / UIScreen.mainScreen().scale
        separatorView.updateConstraint(.Height, constant: separatorHeightInPixels)
        separatorView.backgroundColor   = WPStyleGuide.Notifications.blockSeparatorColor
        
        // Setup Action Buttons
        let textNormalColor             = WPStyleGuide.Notifications.blockActionDisabledColor
        let textSelectedColor           = WPStyleGuide.Notifications.blockActionEnabledColor
        
        let likeNormalTitle             = NSLocalizedString("Like", comment: "Like a comment")
        let likeSelectedTitle           = NSLocalizedString("Liked", comment: "A comment has been liked")

        let approveNormalTitle          = NSLocalizedString("Approve", comment: "Approve a comment")
        let approveSelectedTitle        = NSLocalizedString("Approved", comment: "Unapprove a comment")
        
        let moreTitle                   = NSLocalizedString("More",  comment: "Verb, display More actions for a comment")
        let trashTitle                  = NSLocalizedString("Trash", comment: "Move a comment to the trash")
        
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
        // When disabled, let's hide the button by shrinking it's width
        let width    : CGFloat  = enabled ? buttonWidth     : CGFloat.min
        let trailing : CGFloat  = enabled ? buttonTrailing  : CGFloat.min
        
        button.updateConstraint(.Width, constant: width)
        
        contentView.updateConstraintForView(button, attribute: .Trailing, constant: trailing)
        contentView.updateConstraintForView(button, attribute: .Leading,  constant: trailing)
        
        button.hidden   = !enabled
        button.enabled  = enabled
    }

    private func updateBottomSpacingIfNeeded() {
        //  Note:
        //  =====
        //
        //  When all of the buttons are disabled, let's remove the bottom space.
        //  Since all of the action buttons are linked to the more button, affecting that one will
        //  effectively reflect on the rest
        //
        let hasButtonsEnabled   = isLikeEnabled || isTrashEnabled || isApproveEnabled || isMoreEnabled
        let moreTop             = hasButtonsEnabled ? buttonTop     : CGFloat.min
        let moreHeight          = hasButtonsEnabled ? buttonHeight  : CGFloat.min
        
        contentView.updateConstraintForView(btnMore, attribute: .Top, constant: moreTop)
        btnMore.updateConstraint(.Height, constant: moreHeight)
        setNeedsLayout()
    }
    
    private func applyIndentation(text: NSAttributedString?) -> NSAttributedString? {
        
        // Apply an indentation of `firstLineHeadIndent` pixels, only on the first line!
        let indentedString = text?.mutableCopy() as? NSMutableAttributedString
        if let unwrappedIndentedString = indentedString {
            
            let length      = min(1, unwrappedIndentedString.length)
            let range       = NSRange(location: 0, length: length)
            let paragraph   = WPStyleGuide.Notifications.blockParagraphStyleWithIndentation(firstLineHeadIndent)
            
            unwrappedIndentedString.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
            
            return unwrappedIndentedString
        }
        
        return nil
    }
    
    // MARK: - Constants
    private let separatorHeight                     : CGFloat   = 1
    private let buttonWidth                         : CGFloat   = 55
    private let buttonHeight                        : CGFloat   = 30
    private let buttonTop                           : CGFloat   = 20
    private let buttonTrailing                      : CGFloat   = 20
    private let firstLineHeadIndent                 : CGFloat   = 43
    
    // MARK: - Private
    private let placeholderName                     : String    = "gravatar"
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
