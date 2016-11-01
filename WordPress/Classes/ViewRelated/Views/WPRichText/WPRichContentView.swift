import Foundation
import UIKit

/// A subclass of UITextView for displaying HTML formatted strings.  Embedded content
/// in tags like img, iframe, and video, are loaded manually and presented as subviews.
///
class WPRichContentView: UITextView
{
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
        let source = WPTableImageSource()
        source.delegate = self
        source.forceLargerSizeWhenFetching = false
        source.photonQuality = 65
        return source
    }()

    /// The maximum size for images.
    ///
    lazy var maxDisplaySize: CGSize = {
        let bounds = UIScreen.mainScreen().bounds
        let side = max(bounds.size.width, bounds.size.height)
        return CGSize(width: side, height: side)
    }()

    var content: String {
        get {
            return text ?? ""
        }
        set {
            let str = newValue ?? ""
            let style = "<style>body { font-family: Merriweather; font-size:16.0; line-height:1.6875; color: #2e4453; } a { color: #0087be; text-decoration: none; } a:active { color: #005082 } blockquote { text-style: italic; } </style>"
            let content = style + str
            let attrTxt = try! NSAttributedString.attributedStringFromHTMLString(content, defaultDocumentAttributes: nil)
            attributedText = attrTxt
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
    }

}


extension WPRichContentView: WPTextAttachmentManagerDelegate
{
    func attachmentManager(attachmentManager: WPTextAttachmentManager, viewForAttachment attachment: WPTextAttachment) -> UIView? {
        if attachment.tagName == "img" {

            return imageForAttachment(attachment)

        } else {

            return embedForAttachment(attachment)

        }
    }


    /// Returns the view to use for an image attachment.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment for an image.
    ///
    /// - Returns: A WPRichTextImage instance configured for the attachment.
    ///
    func imageForAttachment(attachment: WPTextAttachment) -> WPRichTextImage {
        let img = WPRichTextImage(frame: CGRect.zero)
        let media = RichMedia(image: img, attachment: attachment)
        let url = NSURL(string: attachment.src)
        img.contentURL = url

        let index = mediaArray.count
        let indexPath = NSIndexPath(forRow: index, inSection: 1)
        imageSource.fetchImageForURL(url, withSize: maxDisplaySize, indexPath: indexPath, isPrivate: false)

        mediaArray.append(media)

        return img
    }


    /// Returns the view to use for an embed attachment.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment for embedded content.
    ///
    /// - Returns: A WPRichTextEmbed instance configured for the attachment.
    ///
    func embedForAttachment(attachment: WPTextAttachment) -> WPRichTextEmbed {
        let width: CGFloat = attachment.width ?? textContainer.size.width
        let height: CGFloat = attachment.height ?? 150.0
        let embed = WPRichTextEmbed(frame: CGRect(x: 0.0, y: 0.0, width: width, height: height))

        attachment.maxSize = CGSize(width: width, height: height)

        if attachment.tagName == "iframe" {
            embed.loadContentURL(NSURL(string: attachment.src.stringByDecodingXMLCharacters())!)
        } else {
            embed.loadHTMLString(attachment.html!)
        }

        embed.success = { [weak self] _ in
            self?.attachmentManager.layoutAttachmentViews()
            self?.invalidateIntrinsicContentSize()
        }

        return embed
    }

}


extension WPRichContentView: WPTableImageSourceDelegate
{

    func tableImageSource(tableImageSource: WPTableImageSource!, imageReady image: UIImage!, forIndexPath indexPath: NSIndexPath!) {
        let richMedia = mediaArray[indexPath.row]

        richMedia.image.imageView.image = image
        richMedia.attachment.maxSize = image.size

        let frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        richMedia.image.frame = frame

        attachmentManager.layoutAttachmentViews()
        invalidateIntrinsicContentSize()
    }


    func tableImageSource(tableImageSource: WPTableImageSource!, imageFailedforIndexPath indexPath: NSIndexPath!, error: NSError!) {
        let richMedia = mediaArray[indexPath.row]
        DDLogSwift.logError("Error loading image: \(richMedia.attachment.src)")
        DDLogSwift.logError("\(error)")
    }
}


/// A simple struct used to keep references to a rich text image and its associated attachment.
///
struct RichMedia
{
    let image: WPRichTextImage
    let attachment: WPTextAttachment
}
