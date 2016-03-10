import Foundation
import WordPressShared

@objc public class ReaderCardDiscoverAttributionView: UIView
{
    @IBOutlet private weak var imageView: CircularImageView!
    @IBOutlet private(set) public weak var richTextView: RichTextView!

    private let gravatarImageName = "gravatar"
    private let blavatarImageName = "post-blavatar-placeholder"


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()
        richTextView.scrollsToTop = false
    }


    // MARK: - Accessors

    public override func intrinsicContentSize() -> CGSize {
        if richTextView.textStorage.length == 0 {
            return super.intrinsicContentSize()
        }
        return sizeThatFits(frame.size)
    }

    public override func sizeThatFits(size: CGSize) -> CGSize {
        let adjustedWidth = size.width - richTextView.frame.minX
        let adjustedSize = CGSize(width: adjustedWidth, height: CGFloat.max)
        var height = richTextView.sizeThatFits(adjustedSize).height
        height = max(height, imageView.frame.maxY)

        return CGSize(width: size.width, height: height)
    }


    // MARK: - Configuration

    public func configureView(contentProvider: ReaderPostContentProvider?) {
        if contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.Post {
            configurePostAttribution(contentProvider!)
        } else if contentProvider?.sourceAttributionStyle() == SourceAttributionStyle.Site {
            configureSiteAttribution(contentProvider!, verboseAttribution: false)
        } else {
            reset()
        }

        invalidateIntrinsicContentSize()
    }


    public func configureViewWithVerboseSiteAttribution(contentProvider: ReaderPostContentProvider?) {
        if let contentProvider = contentProvider {
            configureSiteAttribution(contentProvider, verboseAttribution: true)
        } else {
            reset()
        }
    }


    private func reset() {
        imageView.image = nil
        richTextView.attributedText = nil
    }

    private func configurePostAttribution(contentProvider: ReaderPostContentProvider) {
        let url = contentProvider.sourceAvatarURLForDisplay()
        let placeholder = UIImage(named: gravatarImageName)
        imageView.setImageWithURL(url, placeholderImage: placeholder)
        imageView.shouldRoundCorners = true

        let str = stringForPostAttribution(contentProvider.sourceAuthorNameForDisplay(),
                                            blogName: contentProvider.sourceBlogNameForDisplay())
        let attributes = WPStyleGuide.originalAttributionParagraphAttributes()
        richTextView.attributedText = NSAttributedString(string: str, attributes: attributes)
    }

    private func stringForPostAttribution(authorName: String?, blogName: String?) -> String {
        var str = ""
        if (authorName != nil) && (blogName != nil) {
            let pattern = NSLocalizedString("Originally posted by %@ on %@",
                comment: "Used to attribute a post back to its original author and blog.  The '%@' characters are placholders for the author's name, and the author's blog repsectively.")
            str = String(format: pattern, authorName!, blogName!)

        } else if (authorName != nil) {
            let pattern = NSLocalizedString("Originally posted by %@",
                comment: "Used to attribute a post back to its original author.  The '%@' characters are a placholder for the author's name.")
            str = String(format: pattern, authorName!)

        } else if (blogName != nil) {
            let pattern = NSLocalizedString("Originally posted on %@",
                comment: "Used to attribute a post back to its original blog.  The '%@' characters are a placholder for the blog name.")
            str = String(format: pattern, blogName!)
        }

        return str
    }

    private func patternForSiteAttribution(verbose: Bool) -> String {
        var pattern: String
        if verbose {
            pattern = NSLocalizedString("Visit %@ for more", comment:"A call to action to visit the specified blog.  The '%@' characters are a placholder for the blog name.")
        } else {
            pattern = NSLocalizedString("Visit %@", comment:"A call to action to visit the specified blog.  The '%@' characters are a placholder for the blog name.")
        }
        return pattern
    }

    private func configureSiteAttribution(contentProvider: ReaderPostContentProvider, verboseAttribution verbose:Bool) {
        let url = contentProvider.sourceAvatarURLForDisplay()
        let placeholder = UIImage(named: blavatarImageName)
        imageView.setImageWithURL(url, placeholderImage: placeholder)
        imageView.shouldRoundCorners = false

        let blogName = contentProvider.sourceBlogNameForDisplay()
        let pattern = patternForSiteAttribution(verbose)
        let str = String(format: pattern, blogName)

        let range = (str as NSString).rangeOfString(blogName)
        let font = WPFontManager.systemItalicFontOfSize(WPStyleGuide.originalAttributionFontSize())
        let attributes = WPStyleGuide.siteAttributionParagraphAttributes()
        let attributedString = NSMutableAttributedString(string: str, attributes: attributes)
        attributedString.addAttribute(NSFontAttributeName, value: font, range: range)
        attributedString.addAttribute(NSLinkAttributeName, value: "http://wordpress.com/", range: NSMakeRange(0, str.characters.count))

        richTextView.attributedText = attributedString
    }

}
