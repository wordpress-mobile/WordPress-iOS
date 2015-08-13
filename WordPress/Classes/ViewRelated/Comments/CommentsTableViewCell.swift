import Foundation


public class CommentsTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    public var author : String? {
        didSet {
            if author != oldValue {
                refreshDetailsLabel()
            }
        }
    }
    public var postTitle : String? {
        didSet {
            postTitle = postTitle ?? NSLocalizedString("(No Title)", comment: "Empty Post Title")

            if postTitle != oldValue {
                refreshDetailsLabel()
            }
        }
    }
    public var content : String? {
        didSet {
            if content != oldValue {
                refreshDetailsLabel()
            }
        }
    }
    public var timestamp : String? {
        get {
            return timestampLabel?.text
        }
        set {
            timestampLabel?.text = newValue
        }
    }
    public var approved : Bool = false {
        didSet {
            refreshDetailsLabel()
            refreshBackground()
        }
    }
    
    
    
    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
        
        if url == nil {
            gravatarImageView.image = Style.gravatarPlaceholderImage
            return
        }
        
        let size        = gravatarImageView.frame.width * UIScreen.mainScreen().scale
        let scaledURL   = url!.patchGravatarUrlWithSize(size)
        
        gravatarImageView.downloadImage(scaledURL,
            placeholderImage    : Style.gravatarPlaceholderImage,
            success             :   { (image: UIImage) in
                                        self.gravatarImageView.displayImageWithFadeInAnimation(image)
                                    },
            failure             : nil)
        
        gravatarURL = url
    }
    
    public func downloadGravatarWithGravatarEmail(email: String?) {
        // TODO: For consistency / clarity, let's rename UIImageView+Gravatar helpers in another PR.
        // This helper downloads an image, and it's not simply assigning it!
        gravatarImageView.setImageWithGravatarEmail(email)
    }
    
    
    
    // MARK: - Overwritten Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        assert(gravatarImageView != nil)
        assert(detailsLabel != nil)
        assert(timestampLabel != nil)
        assert(detailsLeadingConstraint != nil)
        assert(detailsTrailingConstraint != nil)
        
        timestampLabel.font = Style.timestampFont
        timestampLabel.textColor = Style.timestampColor
    }
    
    public override func layoutSubviews() {
        // Calculate the TextView's width, before hitting layoutSubviews!
        var maxDetailsWidth = bounds.width
        maxDetailsWidth     -= detailsLeadingConstraint.constant + detailsTrailingConstraint.constant
        maxDetailsWidth     -= gravatarImageView.frame.maxX
        detailsLabel.preferredMaxLayoutWidth = maxDetailsWidth
        
        super.layoutSubviews()
    }
    
    
    
    // MARK: - Private Helpers
    private func refreshDetailsLabel() {
        // Unwrap the Fields
        let unwrappedAuthor     = author    ?? String()
        let unwrappedTitle      = postTitle ?? String()
        let unwrappedContent    = content   ?? String()
        
        // Localize the format
        var title = NSLocalizedString("%1$@ on %2$@", comment: "'AUTHOR on POST TITLE' in a comment list")
        if !unwrappedContent.isEmpty {
            title = NSLocalizedString("%1$@ on %2$@: %3$@", comment: "'AUTHOR on POST TITLE: COMMENT' in a comment list")
        }

        // Replace Author + Title + Content
        let replacementMap = [
            "%1$@" : NSAttributedString(string: unwrappedAuthor,    attributes: Style.titleBoldStyle),
            "%2$@" : NSAttributedString(string: unwrappedTitle,     attributes: Style.titleBoldStyle),
            "%3$@" : NSAttributedString(string: unwrappedContent,   attributes: Style.titleRegularStyle),
        ]
        
        var attributedDetails = NSMutableAttributedString(string: title, attributes: Style.titleRegularStyle)
        
        for (key, attributedString) in replacementMap {
            let range = (attributedDetails.string as NSString).rangeOfString(key)
            if range.location == NSNotFound {
                continue
            }
            
            attributedDetails.replaceCharactersInRange(range, withAttributedString: attributedString)
        }
        
        // Ready!
        detailsLabel.attributedText = attributedDetails
    }
    
    private func refreshBackground() {
// TODO: Implement
    }
    
    
    
    // MARK: - Aliases
    typealias Style = WPStyleGuide.Comments
    
    // MARK: - Private Properties
    private var gravatarURL : NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private var layoutView                : UIView!
    @IBOutlet private var gravatarImageView         : CircularImageView!
    @IBOutlet private var detailsLabel              : UILabel!
    @IBOutlet private var timestampImageView        : UIImageView!
    @IBOutlet private var timestampLabel            : UILabel!
    @IBOutlet private var detailsLeadingConstraint  : NSLayoutConstraint!
    @IBOutlet private var detailsTrailingConstraint : NSLayoutConstraint!
}
