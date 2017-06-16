import Foundation
import UIKit
import CocoaLumberjack
import WordPressShared

@objc protocol WPRichContentViewDelegate: UITextViewDelegate {
    func richContentView(_ richContentView: WPRichContentView, didReceiveImageAction image: WPRichTextImage)
    @objc optional func richContentViewShouldUpdateLayoutForAttachments(_ richContentView: WPRichContentView) -> Bool
    @objc optional func richContentViewDidUpdateLayoutForAttachments(_ richContentView: WPRichContentView)
}


/// A subclass of UITextView for displaying HTML formatted strings.  Embedded content
/// in tags like img, iframe, and video, are loaded manually and presented as subviews.
///
class WPRichContentView: UITextView {
    struct Constants {
        static let photonQuality = 65
        static let textContainerInset = UIEdgeInsetsMake(0.0, 0.0, 16.0, 0.0)
        static let defaultAttachmentHeight = CGFloat(50.0)
    }

    /// Used to keep references to image attachments.
    ///
    var mediaArray = [RichMedia]()

    /// Manages the layout and positioning of text attachments.
    ///
    lazy var attachmentManager: WPTextAttachmentManager = {
        return WPTextAttachmentManager(textView: self, delegate: self)
    }()

    /// Used to load images for attachments.
    ///
    lazy var imageSource: WPTableImageSource = {
        let source = WPTableImageSource(maxSize: self.maxDisplaySize)
        source?.delegate = self
        source?.forceLargerSizeWhenFetching = false
        source?.photonQuality = Constants.photonQuality
        return source!
    }()

    /// The maximum size for images.
    ///
    lazy var maxDisplaySize: CGSize = {
        let bounds = UIScreen.main.bounds
        let side = max(bounds.size.width, bounds.size.height)
        return CGSize(width: side, height: side)
    }()


    let topMarginAttachment = NSTextAttachment()
    let bottomMarginAttachment = NSTextAttachment()

    var topMargin: CGFloat {
        get {
            return topMarginAttachment.bounds.height
        }

        set {
            var bounds = topMarginAttachment.bounds
            bounds.size.height = max(1, newValue)
            bounds.size.width = textContainer.size.width
            topMarginAttachment.bounds = bounds

            if textStorage.length > 0 {
                let rng = NSRange(location: 0, length: 1)
                layoutManager.invalidateLayout(forCharacterRange: rng, actualCharacterRange: nil)
                layoutManager.ensureLayout(forCharacterRange: rng)
                attachmentManager.layoutAttachmentViews()
            }
        }
    }

    // NOTE: Avoid setting attachment bounds with a zero height. A zero height
    // for an attachment at the end of a text run can glitch TextKit's layout
    // causing glyphs to not be drawn.
    var bottomMargin: CGFloat {
        get {
            return bottomMarginAttachment.bounds.height
        }

        set {
            var bounds = bottomMarginAttachment.bounds
            bounds.size.height = max(1, newValue)
            bounds.size.width = textContainer.size.width
            bottomMarginAttachment.bounds = bounds

            if textStorage.length > 1 {
                let rng = NSRange(location: textStorage.length - 2, length: 1)
                layoutManager.invalidateLayout(forCharacterRange: rng, actualCharacterRange: nil)
                layoutManager.ensureLayout(forCharacterRange: rng)
                attachmentManager.layoutAttachmentViews()
            }
        }
    }

    override var textContainerInset: UIEdgeInsets {
        didSet {
            attachmentManager.layoutAttachmentViews()
        }
    }


    /// Whether the view shows private content. Used when fetching images.
    ///
    var isPrivate = false

    var content: String {
        get {
            return text ?? ""
        }
        set {
            let str = newValue
            let style = "<style>" +
                "body { font:-apple-system-subheadline; font-family: 'Noto Serif'; font-weight: normal; line-height:1.6875; color: #2e4453; }" +
                "blockquote { color:#4f748e; } " +
                "em, i { font:-apple-system-subheadline; font-family: 'Noto Serif'; font-weight: normal; font-style: italic; } " +
                "a { color: #0087be; text-decoration: none; } " +
                "a:active { color: #005082; } " +
                "</style>"
            let content = style + str
            // Request the font to ensure it's loaded. Otherwise NSAttributedString
            // falls back to Times New Roman :o
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/6564
            _ = WPFontManager.notoItalicFont(ofSize: 16)
            do {
                if let attrTxt = try NSAttributedString.attributedStringFromHTMLString(content, defaultDocumentAttributes: nil) {
                    let mattrTxt = NSMutableAttributedString(attributedString: attrTxt)

                    // Ensure the starting paragraph style is applied to the topMarginAttachment else the
                    // first paragraph might not have the correct line height.
                    var paraStyle = NSParagraphStyle.default
                    if attrTxt.length > 0 {
                        if let pstyle = attrTxt.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                            paraStyle = pstyle
                        }
                    }
                    mattrTxt.insert(NSAttributedString(attachment: topMarginAttachment), at: 0)
                    mattrTxt.addAttributes([NSParagraphStyleAttributeName: paraStyle], range: NSRange(location: 0, length: 1))
                    mattrTxt.append(NSAttributedString(attachment: bottomMarginAttachment))

                    attributedText = mattrTxt
                }
            } catch let error {
                DDLogError("Error converting post content to attributed string: \(error)")
                text = NSLocalizedString("There was a problem displaying this post.", comment: "A short error message letting the user know about a problem displaying a post.")
            }
        }
    }

    override var attributedText: NSAttributedString! {
        didSet {
            attachmentManager.enumerateAttachments()
        }
    }


    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        setupView()
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }


    /// A convenience method for one-time, common setup that should be done in init.
    ///
    func setupView() {
        // Because the attachment manager is a lazy property.
        _ = attachmentManager

        textContainerInset = Constants.textContainerInset
    }


    func layoutAttachmentViews() {
        if let richDelegate = delegate as? WPRichContentViewDelegate {
            if richDelegate.richContentViewShouldUpdateLayoutForAttachments?(self) == false {
                return
            }
        }

        updateLayoutForAttachments()

        if let richDelegate = delegate as? WPRichContentViewDelegate {
            richDelegate.richContentViewDidUpdateLayoutForAttachments?(self)
        }
    }


    func updateLayoutForAttachments() {
        attachmentManager.layoutAttachmentViews()
        invalidateIntrinsicContentSize()
    }

}


extension WPRichContentView: WPTextAttachmentManagerDelegate {
    func attachmentManager(_ attachmentManager: WPTextAttachmentManager, viewForAttachment attachment: WPTextAttachment) -> UIView? {
        if attachment.tagName == "img" {
            return imageForAttachment(attachment)

        } else {
            return embedForAttachment(attachment)
        }
    }


    /// Returns the view to use for an embed attachment.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment for embedded content.
    ///
    /// - Returns: A WPRichTextEmbed instance configured for the attachment.
    ///
    func embedForAttachment(_ attachment: WPTextAttachment) -> WPRichTextEmbed {
        let width: CGFloat = attachment.width > 0 ? attachment.width : textContainer.size.width
        let height: CGFloat = attachment.height > 0 ? attachment.height : Constants.defaultAttachmentHeight
        let embed = WPRichTextEmbed(frame: CGRect(x: 0.0, y: 0.0, width: width, height: height))

        attachment.maxSize = CGSize(width: width, height: height)

        if attachment.tagName == "iframe", let url = URL(string: attachment.src.stringByDecodingXMLCharacters()) {
            embed.loadContentURL(url)
        } else {
            let html = attachment.html ?? ""
            embed.loadHTMLString(html as NSString)
        }

        embed.success = { [weak self] embedView in
            if embedView.documentSize.height > attachment.maxSize.height {
                attachment.maxSize.height = embedView.documentSize.height
            }
            self?.layoutAttachmentViews()
        }

        return embed
    }


    /// Returns the view to use for an image attachment.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment for an image.
    ///
    /// - Returns: A WPRichTextImage instance configured for the attachment.
    ///
    func imageForAttachment(_ attachment: WPTextAttachment) -> WPRichTextImage {
        guard let url = URL(string: attachment.src) else {
            return WPRichTextImage(frame: CGRect.zero)
        }

        // Until we have a loaded image use a 1/1 height.  We want a nonzero value
        // to avoid an edge case issue where 0 frames are not correctly updated
        // during rotation.
        attachment.maxSize = CGSize(width: 1, height: 1)

        let img = WPRichTextImage(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        img.addTarget(self, action: #selector(type(of: self).handleImageTapped(_:)), for: .touchUpInside)
        img.contentURL = url
        img.linkURL = linkURLForImageAttachment(attachment)

        if let cachedImage = imageSource.image(for: url, with: maxDisplaySize) {
            img.imageView.image = cachedImage
            attachment.maxSize = cachedImage.size
        } else {
            let index = mediaArray.count
            let indexPath = IndexPath(row: index, section: 1)
            imageSource.fetchImage(for: url, with: maxDisplaySize, indexPath: indexPath, isPrivate: isPrivate)
        }

        let media = RichMedia(image: img, attachment: attachment)
        mediaArray.append(media)

        return img
    }


    /// Retrieves the URL for a link wrapping a text attachment, if one exists.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment instance.
    ///
    /// - Returns: An NSURL optional.
    ///
    func linkURLForImageAttachment(_ attachment: WPTextAttachment) -> URL? {
        var link: URL?
        let attrText = attributedText
        attrText?.enumerateAttachments { (textAttachment, range) in
            if textAttachment == attachment {
                var effectiveRange = NSRange()
                if let value = attrText?.attribute(NSLinkAttributeName, at: range.location, longestEffectiveRange: &effectiveRange, in: NSRange(location: 0, length: (attrText?.length)!)) as? URL {
                    link = value
                }
            }
        }
        return link
    }


    /// Get the NSRange for the specified attachment in the attributedText.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment instance.
    ///
    /// - Returns: An NSRange optional.
    ///
    func rangeOfAttachment(_ attachment: WPTextAttachment) -> NSRange? {
        var attachmentRange: NSRange?
        let attrText = attributedText
        attrText?.enumerateAttachments { (textAttachment, range) in
            if attachment == textAttachment {
                attachmentRange = range
            }
        }
        return attachmentRange
    }


    /// Get the NSRange for the attachment associated with the specified WPRichTextImage instance.
    ///
    /// - Parameters:
    ///     - richTextImage: A WPRichTextImage instance.
    ///
    /// - Returns: An NSRange optional.
    ///
    func attachmentRangeForRichTextImage(_ richTextImage: WPRichTextImage) -> NSRange? {
        for item in mediaArray {
            if item.image == richTextImage {
                return rangeOfAttachment(item.attachment)
            }
        }
        return nil
    }


    /// Notifies the delegate of an user interaction with a WPRichTextImage instance.
    ///
    /// - Parameters:
    ///     - sender: The WPRichTextImage that was tapped.
    ///
    func handleImageTapped(_ sender: WPRichTextImage) {
        guard let delegate = delegate else {
            return
        }

        if let url = sender.linkURL,
            let range = attachmentRangeForRichTextImage(sender) {

            _ = delegate.textView?(self, shouldInteractWith: url as URL, in: range, interaction: .invokeDefaultAction)
            return
        }

        guard let richDelegate = delegate as? WPRichContentViewDelegate else {
            return
        }
        richDelegate.richContentView(self, didReceiveImageAction: sender)
    }
}


extension WPRichContentView: WPTableImageSourceDelegate {

    func tableImageSource(_ tableImageSource: WPTableImageSource!, imageReady image: UIImage!, for indexPath: IndexPath!) {
        let richMedia = mediaArray[indexPath.row]

        richMedia.image.imageView.image = image
        richMedia.attachment.maxSize = image.size

        layoutAttachmentViews()
    }

    func tableImageSource(_ tableImageSource: WPTableImageSource!, imageFailedforIndexPath indexPath: IndexPath!, error: Error!) {
        let richMedia = mediaArray[indexPath.row]
        DDLogError("Error loading image: \(richMedia.attachment.src)")
        DDLogError("\(error)")
    }
}


/// A simple struct used to keep references to a rich text image and its associated attachment.
///
struct RichMedia {
    let image: WPRichTextImage
    let attachment: WPTextAttachment
}
