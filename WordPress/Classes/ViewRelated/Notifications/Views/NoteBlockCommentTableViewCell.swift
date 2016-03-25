import Foundation
import WordPressShared.WPStyleGuide

@objc public class NoteBlockCommentTableViewCell : NoteBlockTextTableViewCell
{
    public typealias EventHandler = ((sender: AnyObject) -> Void)

    // MARK: - Public Properties
    public var onDetailsClick: EventHandler?

    public var attributedCommentText: NSAttributedString? {
        didSet {
            refreshApprovalColors()
        }
    }
    public var commentText: String? {
        set {
            let text = newValue ?? String()
            attributedCommentText = NSMutableAttributedString(string: text, attributes: Style.contentBlockRegularStyle)
        }
        get {
            return attributedCommentText?.string
        }
    }
    public var isApproved: Bool = false {
        didSet {
            refreshApprovalColors()
            refreshSeparators()
        }
    }
    public var hasReply: Bool = false {
        didSet {
            refreshSeparators()
        }
    }
    public var name: String? {
        set {
            titleLabel.text  = newValue
        }
        get {
            return titleLabel.text
        }
    }
    public var timestamp: String? {
        didSet {
            refreshDetails()
        }
    }
    public var site: String? {
        didSet {
            refreshDetails()
        }
    }
    
    

    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        let placeholderImage = Style.blockGravatarPlaceholderImage(isApproved: isApproved)
        let gravatar = url.flatMap { Gravatar($0) }

        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)
    }

    public func downloadGravatarWithGravatarEmail(email: String?) {
        let fallbackImage = Style.blockGravatarPlaceholderImage(isApproved: isApproved)
        gravatarImageView.setImageWithGravatarEmail(email, fallbackImage: fallbackImage)
    }
    

    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Labels
        titleLabel.font                     = Style.blockBoldFont
        detailsLabel.font                   = Style.blockRegularFont

        // Setup Recognizers
        detailsLabel.gestureRecognizers     = [ UITapGestureRecognizer(target: self, action: #selector(NoteBlockCommentTableViewCell.detailsWasPressed(_:))) ]
        detailsLabel.userInteractionEnabled = true
        
        // Force iPad Size Class
        // Why? why, why?. Because, although it's set as a Size Class, Autolayout won't actually apply the 
        // right Gravatar Size until this view moves to a superview. 
        // And guess what? Autosizing cells are, of course, broken in iOS 8, non existant in iOS 7, and we need
        // to perform our own calculation.
        // 
        if UIDevice.isPad() {
            gravatarImageView.updateConstraint(.Width, constant: gravatarPadSize.width)
            gravatarImageView.updateConstraint(.Height, constant: gravatarPadSize.height)
        }
    }
    

    
    // MARK: - Approval Color Helpers
    public override func refreshSeparators() {
        // Left Separator
        separatorsView.leftVisible = !isApproved
        separatorsView.leftColor = Style.blockUnapprovedSideColor
        
        // Bottom Separator
        var bottomInsets = separatorUnapprovedInsets
        if isApproved {
            bottomInsets = hasReply ? separatorRepliedInsets : separatorApprovedInsets
        }
        
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = bottomInsets
        separatorsView.bottomColor = Style.blockSeparatorColorForComment(isApproved: isApproved)
        
        // Background
        separatorsView.backgroundColor = Style.blockBackgroundColorForComment(isApproved: isApproved)
    }

    private func refreshDetails() {
        var details = timestamp ?? String()
        if let unwrappedSite = site {
            details = String(format: "%@ • %@", details, unwrappedSite)
        }
        
        detailsLabel.text = details
    }

    private func refreshApprovalColors() {
        // Refresh Colors
        titleLabel.textColor        = Style.blockTitleColorForComment(isApproved: isApproved)
        detailsLabel.textColor      = Style.blockDetailsColorForComment(isApproved: isApproved)
        linkColor                   = Style.blockLinkColorForComment(isApproved: isApproved)
        attributedText              = isApproved ? attributedCommentText : attributedCommentUnapprovedText
    }
    
    private var attributedCommentUnapprovedText : NSAttributedString? {
        if attributedCommentText == nil {
            return nil
        }

        let unwrappedMutableString  = attributedCommentText!.mutableCopy() as! NSMutableAttributedString
        let range                   = NSRange(location: 0, length: unwrappedMutableString.length)
        let textColor               = Style.blockUnapprovedTextColor
        unwrappedMutableString.addAttribute(NSForegroundColorAttributeName, value: textColor, range: range)

        return unwrappedMutableString
    }

    
    
    
    // MARK: - Event Handlers
    @IBAction public func detailsWasPressed(sender: AnyObject) {
        onDetailsClick?(sender: sender)
    }



    // MARK: - Aliases
    typealias Style = WPStyleGuide.Notifications
    
    // MARK: - Private Constants
    private let separatorApprovedInsets             = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
    private let separatorUnapprovedInsets           = UIEdgeInsetsZero
    private let separatorRepliedInsets              = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
    private let gravatarPadSize                     = CGSize(width: 37.0, height: 37.0)
    
    // MARK: - IBOutlets
    @IBOutlet private weak var actionsView          : UIView!
    @IBOutlet private weak var gravatarImageView    : CircularImageView!
    @IBOutlet private weak var titleLabel           : UILabel!
    @IBOutlet private weak var detailsLabel         : UILabel!
}
