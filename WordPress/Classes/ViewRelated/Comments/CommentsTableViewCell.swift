import Foundation


public class CommentsTableViewCell : UITableViewCell
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
    public var isApproved : Bool = false {
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
        
        timestampLabel.font = Style.timestampFont
        timestampLabel.textColor = Style.timestampColor
    }
    
    
    
    // MARK: - Private Helpers
    private func refreshDetailsLabel() {
// TODO: Implement
        
//        The code ahead might look odd, but it's a way to retain the formatting
//        we want and make the string easy to translate
//        
//        Note that we use printf modifiers because translators will be used to those
//        and less likely to break them, but we do the substitutions manually so we
//        can replace both the placeholders' content and their formatting.
//
        
        let unwrappedContent    = content ?? String()
        let unwrappedAuthor     = author ?? String()
        let unwrappedTitle      = postTitle ?? String()
        
        let title : String
        if unwrappedContent.isEmpty {
            title = NSLocalizedString("%1$@ on %2$@", comment: "'AUTHOR on POST TITLE' in a comment list")
        } else {
            title = NSLocalizedString("%1$@ on %2$@: %3$@", comment: "'AUTHOR on POST TITLE: COMMENT' in a comment list")
        }

        let attributedDetails   = NSMutableAttributedString(string: title, attributes: Style.titleRegularStyle)
        let rawString           = attributedDetails.string as NSString
        let authorRange         = rawString.rangeOfString("%1$@")

        if authorRange.location != NSNotFound {
            let author = NSAttributedString(string: unwrappedAuthor, attributes: Style.titleBoldStyle)
            attributedDetails.replaceCharactersInRange(authorRange, withAttributedString: author)
        }

        
//        NSRange postTitleRange = [[attributedTitle string] rangeOfString:@"%2$@"];
//        if (postTitleRange.location != NSNotFound) {
//            [attributedTitle replaceCharactersInRange:postTitleRange withAttributedString:[[NSAttributedString alloc] initWithString:postTitle attributes:[[self class] titleAttributesBold]]];
//        }
//
//        NSRange contentRange = [[attributedTitle string] rangeOfString:@"%3$@"];
//        if (contentRange.location != NSNotFound) {
//            [attributedTitle replaceCharactersInRange:contentRange withString:content];
//        }

        
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
    @IBOutlet private var gravatarImageView : CircularImageView!
    @IBOutlet private var detailsLabel : UILabel!
    @IBOutlet private var timestampLabel : UILabel!
}
