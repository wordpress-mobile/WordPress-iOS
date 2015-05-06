import Foundation


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
            attributedCommentText = NSMutableAttributedString(string: text, attributes: Style.blockRegularStyle)
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
        if url == gravatarURL {
            return
        }
        
        let success = { (image: UIImage) in
            self.gravatarImageView.displayImageWithFadeInAnimation(image)
        }
        
        let placeholderImage = Style.gravatarPlaceholderImage
        gravatarImageView.downloadImage(url, placeholderImage: placeholderImage, success: success, failure: nil)
        
        gravatarURL = url
    }

    public func downloadGravatarWithGravatarEmail(email: String?) {
        gravatarImageView.setImageWithGravatarEmail(email)
    }
    

    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Labels
        titleLabel.font                     = Style.blockBoldFont
        detailsLabel.font                   = Style.blockRegularFont

        // Setup Recognizers
        detailsLabel.gestureRecognizers     = [ UITapGestureRecognizer(target: self, action: "detailsWasPressed:") ]
        detailsLabel.userInteractionEnabled = true

        // iPad: Use a bigger image size!
        if UIDevice.isPad() {
            gravatarImageView.updateConstraint(.Height, constant: gravatarImageSizePad.width)
            gravatarImageView.updateConstraint(.Width,  constant: gravatarImageSizePad.height)
        }
    }
    

    // MARK: - Separator Helpers
    public override func refreshSeparators() {
        // Left Separator
        separatorsView.leftVisible          = !isApproved
        separatorsView.leftColor            = Style.blockUnapprovedSideColor
        
        // Bottom Separator
        var bottomInsets                    = separatorUnapprovedInsets
        if isApproved {
            bottomInsets                    = hasReply ? separatorRepliedInsets : separatorApprovedInsets
        }
        
        separatorsView.bottomVisible        = true
        separatorsView.bottomInsets         = bottomInsets
    }

    // MARK: - Private Methods
    private func refreshDetails() {
        var details = timestamp ?? String()
        if let unwrappedSite = site {
            details = String(format: "%@ • %@", details, unwrappedSite)
        }
        
        detailsLabel.text = details
    }

    private func refreshApprovalColors() {
        // Separators
        separatorsView.bottomColor  = Style.blockSeparatorColorForComment(isApproved: isApproved)
        
        // Background
        contentView.backgroundColor = Style.blockBackgroundColorForComment(isApproved: isApproved)
        
        // Refresh Colors
        titleLabel.textColor        = Style.blockTitleColorForComment(isApproved: isApproved)
        detailsLabel.textColor      = Style.blockDetailsColorForComment(isApproved: isApproved)
        super.linkColor             = Style.blockLinkColorForComment(isApproved: isApproved)
        super.attributedText        = isApproved ? attributedCommentText : attributedCommentUnapprovedText
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
        if let handler = onDetailsClick {
            handler(sender: sender)
        }
    }
    
    // MARK: - Private Constants
    private let gravatarImageSizePad                = CGSize(width: 37.0, height: 37.0)
    private let separatorApprovedInsets             = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
    private let separatorUnapprovedInsets           = UIEdgeInsetsZero
    private let separatorRepliedInsets              = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
    
    // MARK: - Private Properties
    private var gravatarURL                         : NSURL?

    // MARK: - Aliases
    typealias Style                                 = WPStyleGuide.Notifications

    // MARK: - IBOutlets
    @IBOutlet private weak var actionsView          : UIView!
    @IBOutlet private weak var gravatarImageView    : CircularImageView!
    @IBOutlet private weak var titleLabel           : UILabel!
    @IBOutlet private weak var detailsLabel         : UILabel!
}
