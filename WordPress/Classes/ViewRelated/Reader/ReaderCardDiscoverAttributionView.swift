import Foundation

@objc public class ReaderCardDiscoverAttributionView: UIView
{
    @IBOutlet private weak var imageView: CircularImageView!
    @IBOutlet private weak var richTextView: RichTextView!

    private let gravatarImageName = "gravatar-reader"
    private let blavatarImageName = "post-blavatar-placeholder"


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
            configureSiteAttribution(contentProvider!)
        } else {
            reset()
        }

        invalidateIntrinsicContentSize()
    }

    private func reset() {
        imageView.image = nil
        richTextView.attributedText = nil
    }

    private func configurePostAttribution(contentProvider: ReaderPostContentProvider) {

        var url = contentProvider.sourceAvatarURLForDisplay()
        var placeholder = UIImage(named: gravatarImageName)
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

    private func configureSiteAttribution(contentProvider: ReaderPostContentProvider) {
        var url = contentProvider.sourceAvatarURLForDisplay()
        var placeholder = UIImage(named: blavatarImageName)
        imageView.setImageWithURL(url, placeholderImage: placeholder)
        imageView.shouldRoundCorners = false

        let pattern = NSLocalizedString("Visit %@", comment:"A call to action to visit the specified blog.  The '%@' characters are a placholder for the blog name.")
        let str = String(format: pattern, contentProvider.sourceBlogNameForDisplay())

        let attributes = WPStyleGuide.originalAttributionParagraphAttributes()
        richTextView.attributedText = NSAttributedString(string: str, attributes: attributes);
    }

}
