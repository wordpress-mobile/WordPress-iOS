import Foundation


public class CommentsTableViewCell : UITableViewCell
{
    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
        
        let success = { (image: UIImage) in
            self.gravatarImageView.displayImageWithFadeInAnimation(image)
        }
        
        let placeholderImage = UIImage(named: placeholder)
        gravatarImageView.downloadImage(url, placeholderImage: placeholderImage, success: success, failure: nil)
        
        gravatarURL = url
    }
    
    public var details : NSAttributedString? {
        get {
            return detailsLabel.attributedText
        }
        set {
            detailsLabel.attributedText = newValue ?? NSAttributedString()
        }
    }
    
    public var timestamp : String? {
        get {
            return timestampLabel?.text
        }
        set {
            timestampLabel.text = newValue ?? String()
        }
    }
    
    public var isApproved: Bool = false {
        didSet {
    // TODO: Moderation?
        }
    }
    
    
    // MARK: - Overwritten Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        assert(gravatarImageView    != nil)
        assert(detailsLabel         != nil)
        assert(timestampLabel       != nil)
        
        timestampLabel.font         = WPFontManager.openSansSemiBoldFontOfSize(12)
        timestampLabel.textColor    = UIColor(red: 0xA7/255.0, green: 0xBB/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
    }
    
    
    // MARK: - Constants
    private let placeholder = "gravatar"
    
    // MARK: - Private Properties
    private var gravatarURL                 : NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private var gravatarImageView : UIImageView!
    @IBOutlet private var detailsLabel      : UILabel!
    @IBOutlet private var timestampLabel    : UILabel!
}

//+ (NSAttributedString *)titleAttributedTextForContentProvider:(id<WPContentViewProvider>)contentProvider
//{
//    // combine author and title
//    NSString *author = [contentProvider authorForDisplay];
//    NSString *postTitle = [contentProvider titleForDisplay];
//    NSString *content = [contentProvider contentPreviewForDisplay];
//    if (!(postTitle.length > 0)) {
//        postTitle = NSLocalizedString(@"(No Title)", nil);
//    }
//    
//    The code ahead might look odd, but it's a way to retain the formatting
//    we want and make the string easy to translate
//    
//    Note that we use printf modifiers because translators will be used to those
//    and less likely to break them, but we do the substitutions manually so we
//    can replace both the placeholders' content and their formatting.
//    NSString *title;
//    if (content.length > 0) {
//        title = NSLocalizedString(@"%1$@ on %2$@: %3$@", @"'AUTHOR on POST TITLE: COMMENT' in a comment list");
//    } else {
//        title = NSLocalizedString(@"%1$@ on %2$@", @"'AUTHOR on POST TITLE' in a comment list");
//    }
//    
//    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:[[self class] titleAttributes]];
//    
//    NSRange authorRange = [[attributedTitle string] rangeOfString:@"%1$@"];
//    if (authorRange.location != NSNotFound) {
//        [attributedTitle replaceCharactersInRange:authorRange withAttributedString:[[NSAttributedString alloc] initWithString:author attributes:[[self class] titleAttributesBold]]];
//    }
//    
//    NSRange postTitleRange = [[attributedTitle string] rangeOfString:@"%2$@"];
//    if (postTitleRange.location != NSNotFound) {
//        [attributedTitle replaceCharactersInRange:postTitleRange withAttributedString:[[NSAttributedString alloc] initWithString:postTitle attributes:[[self class] titleAttributesBold]]];
//    }
//    
//    NSRange contentRange = [[attributedTitle string] rangeOfString:@"%3$@"];
//    if (contentRange.location != NSNotFound) {
//        [attributedTitle replaceCharactersInRange:contentRange withString:content];
//    }
//    
//    return attributedTitle;
//}
