import Foundation
import UIKit
import CocoaLumberjack
import WordPressShared

@objc protocol WPRichContentViewDelegate: UITextViewDelegate {
    func richContentView(_ richContentView: WPRichContentView, didReceiveImageAction image: WPRichTextImage)
    @objc optional func richContentViewShouldUpdateLayoutForAttachments(_ richContentView: WPRichContentView) -> Bool
    @objc optional func richContentViewDidUpdateLayoutForAttachments(_ richContentView: WPRichContentView)
    @objc optional func interactWith(URL: URL)
}


/// A subclass of UITextView for displaying HTML formatted strings.  Embedded content
/// in tags like img, iframe, and video, are loaded manually and presented as subviews.
///
class WPRichContentView: UITextView {

    /// Used to keep references to image attachments.
    ///
    var mediaArray = [RichMedia]()

    /// Manages the layout and positioning of text attachments.
    ///
    @objc lazy var attachmentManager: WPTextAttachmentManager = {
        return WPTextAttachmentManager(textView: self, delegate: self)
    }()

    /// The maximum size for images.
    ///
    @objc lazy var maxDisplaySize: CGSize = {
        let bounds = UIScreen.main.bounds
        let side = max(bounds.size.width, bounds.size.height)
        return CGSize(width: side, height: side)
    }()

    private func setupTouchDetection() {
        addGestureRecognizer(linkTapGestureRecognizer)
    }

    @objc lazy var linkTapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
              let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRecognized))
              gestureRecognizer.cancelsTouchesInView = true
              gestureRecognizer.delaysTouchesBegan = true
              gestureRecognizer.delaysTouchesEnded = true
              gestureRecognizer.delegate = self
              return gestureRecognizer
          }()

    override var textContainerInset: UIEdgeInsets {
        didSet {
            attachmentManager.layoutAttachmentViews()
        }
    }


    /// Whether the view shows private content. Used when fetching images.
    ///
    @objc var isPrivate = false

    @objc var content: String {
        get {
            return text ?? ""
        }
        set {
            attributedText = WPRichContentView.formattedAttributedStringForString(newValue)
        }
    }

    private static let fallbackTextColorHex = "000"

    override var attributedText: NSAttributedString! {
        didSet {
            attachmentManager.enumerateAttachments()
        }
    }

    @objc class func formattedAttributedStringForString(_ string: String) -> NSAttributedString {
        let style = AttributedStringStyle(textColorHex: UIColor.text.hexString() ?? fallbackTextColorHex,
                                          blockQuoteColorHex: UIColor.textSubtle.hexString() ?? fallbackTextColorHex,
                                          linkColorHex: UIColor.primary.hexString() ?? fallbackTextColorHex,
                                          linkColorActiveHex: UIColor.primaryDark.hexString() ?? fallbackTextColorHex)
        return formattedAttributedString(for: string, style: style)
    }

    @available(iOS 13, *)
    class func formattedAttributedString(for string: String, style: UIUserInterfaceStyle) -> NSAttributedString {
        let trait = UITraitCollection(userInterfaceStyle: style)
        let style = AttributedStringStyle(textColorHex: UIColor.text.color(for: trait).hexString() ?? fallbackTextColorHex,
                                          blockQuoteColorHex: UIColor.textSubtle.color(for: trait).hexString() ?? fallbackTextColorHex,
                                          linkColorHex: UIColor.primary.color(for: trait).hexString() ?? fallbackTextColorHex,
                                          linkColorActiveHex: UIColor.primaryDark.color(for: trait).hexString() ?? fallbackTextColorHex)
        return formattedAttributedString(for: string, style: style)
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        let container = NSTextContainer(size: frame.size)
        let storage = NSTextStorage()
        let manager = BlockquoteBackgroundLayoutManager()

        storage.addLayoutManager(manager)
        manager.addTextContainer(container)

        super.init(frame: frame, textContainer: container)

        setupView()
    }


    required init?(coder aDecoder: NSCoder) {
        DDLogDebug("This class should be initialized via code, in order to properly render blockquotes. We need to be able to ovverride the default `textContainer`, and we don't have opportunity to do so when unpacking from a `nib`. Sorry for that :(")
        super.init(coder: aDecoder)

        setupView()
    }

    /// A convenience method for one-time, common setup that should be done in init.
    ///
    @objc func setupView() {
        // Because the attachment manager is a lazy property.
        _ = attachmentManager

        textContainerInset = Constants.textContainerInset
        setupTouchDetection()
    }


    @objc func layoutAttachmentViews() {
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


    @objc func updateLayoutForAttachments() {
        attachmentManager.layoutAttachmentViews()
        invalidateIntrinsicContentSize()
    }


    func ensureLayoutForAttachment(_ textAttachment: NSTextAttachment) {
        guard textStorage.length > 0 else {
            return
        }

        attributedText.enumerateAttachments { (attachment, range) in
            if attachment == textAttachment {
                self.ensureLayoutForAttachment(attachment, at: range)
            }
        }
    }

    @objc func tapRecognized(_ recognizer: UIGestureRecognizer) {
        let point = recognizer.location(in: self)
        let characterIndex = self.layoutManager.characterIndex(for: point, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        // handle tap on link
        if let linkAttribute = self.attributedText?.attribute(.link, at: characterIndex, effectiveRange: nil),
            let url = linkAttribute as? URL,
            let richDelegate = delegate as? WPRichContentViewDelegate {
            richDelegate.interactWith?(URL: url)
        }
    }

    struct AttributedStringStyle {
        let textColorHex: String
        let blockQuoteColorHex: String
        let linkColorHex: String
        let linkColorActiveHex: String
    }
}

private extension WPRichContentView {
    class func formattedAttributedString(for string: String, style: AttributedStringStyle) -> NSAttributedString {
        let styleString = "<style>" +
            "body { font:-apple-system-body; font-family: 'Noto Serif'; font-weight: normal; line-height:1.6; color: #\(style.textColorHex); }" +
            "blockquote { color:#\(style.blockQuoteColorHex); } " +
            "em, i { font:-apple-system-body; font-family: 'Noto Serif'; font-weight: normal; font-style: italic; line-height:1.6; } " +
            "a { color: #\(style.linkColorHex); text-decoration: none; } " +
            "a:active { color: #\(style.linkColorActiveHex); } " +
        "</style>"
        let html = styleString + string

        // Request the font to ensure it's loaded. Otherwise NSAttributedString
        // falls back to Times New Roman :o
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/6564
        _ = WPFontManager.notoItalicFont(ofSize: 16)
        do {
            if let attrTxt = try NSAttributedString.attributedStringFromHTMLString(html, defaultAttributes: nil) {
                return attrTxt
            }
        } catch let error {
            DDLogError("Error converting post content to attributed string: \(error)")
        }
        let text = NSLocalizedString("There was a problem displaying this post.", comment: "A short error message letting the user know about a problem displaying a post.")
        return NSAttributedString(string: text)
    }

    func ensureLayoutForAttachment(_ attachment: NSTextAttachment, at range: NSRange) {
        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        layoutManager.ensureLayout(forCharacterRange: range)
        attachmentManager.layoutAttachmentViews()
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
    @objc func embedForAttachment(_ attachment: WPTextAttachment) -> WPRichTextEmbed {
        let width: CGFloat = attachment.width > 0 ? attachment.width : textContainer.size.width
        let height: CGFloat = attachment.height > 0 ? attachment.height : Constants.defaultAttachmentHeight
        let embed = WPRichTextEmbed(frame: CGRect(x: 0.0, y: 0.0, width: width, height: height))

        // Set an inital max size for the attachment, but the attachment will modify this when its loaded.
        attachment.maxSize = embed.frame.size

        if attachment.tagName == "iframe", let url = URL(string: attachment.src.stringByDecodingXMLCharacters()) {
            embed.loadContentURL(url)
        } else {
            let html = attachment.html ?? ""
            embed.loadHTMLString(html as NSString)
        }

        embed.success = { [weak self] embedView in
            if embedView.contentSize().width > attachment.maxSize.width || embedView.contentSize().height > attachment.maxSize.height {
                attachment.maxSize = embedView.contentSize()
            }
            self?.layoutAttachmentViews()
        }

        return embed
    }


    /// Find the most appropriate size for a gif image to be loaded efficiently without loosing much quality.
    /// With height: 0, the image will resize proportionally, and won't grow bigger than its original size.
    ///
    /// - url: The URL for the image.
    /// - Parameter size: The proposed size for the gif image.
    /// - Returns: The most efficient size with good quality.
    fileprivate func efficientImageSize(with url: URL, proposedSize size: CGSize) -> CGSize {
        guard url.isGif else {
            return size
        }

        // Dont load bigger images in landscape mode.
        let maximumImageWidth = min(maxDisplaySize.height, maxDisplaySize.width)

        // Don't resize small images. Resizing bigger images will also affect quality, saving extra memory.
        if size.width < maximumImageWidth && size.height < maximumImageWidth {
            return CGSize(width: maximumImageWidth, height: 0)
        } else {
            return CGSize(width: maximumImageWidth/2, height: 0)
        }
    }


    /// Creates and return a `WPRichTextImage` with the given parameters.
    ///
    fileprivate func richTextImage(with size: CGSize, _ url: URL, _ attachment: WPTextAttachment) -> WPRichTextImage {
        let image = WPRichTextImage(frame: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        image.addTarget(self, action: #selector(type(of: self).handleImageTapped(_:)), for: .touchUpInside)
        image.contentURL = url
        image.linkURL = linkURLForImageAttachment(attachment)
        return image
    }


    /// Returns the CGSize instance for the given `WPTextAttachment`
    ///
    fileprivate func sizeForAttachment(_ attachment: WPTextAttachment) -> CGSize {
        var width: CGFloat = maxDisplaySize.width
        if attachment.width > 0 && attachment.width != .greatestFiniteMagnitude {
            width = attachment.width
        }

        var height: CGFloat = maxDisplaySize.height
        if attachment.height > 0 {
            height = attachment.height
        }

        let r = width / height

        // Enforce max dimensions
        if width > maxDisplaySize.width {
            width = maxDisplaySize.width
            height = width / r
        }
        if height > maxDisplaySize.height {
            height = maxDisplaySize.height
            width = height * r
        }

        return CGSize(width: ceil(width), height: ceil(height))
    }

    /// Returns the view to use for an image attachment.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment for an image.
    ///
    /// - Returns: A WPRichTextImage instance configured for the attachment.
    ///
    @objc func imageForAttachment(_ attachment: WPTextAttachment) -> WPRichTextImage {
        guard let url = URL(string: attachment.src) else {
            return WPRichTextImage(frame: CGRect.zero)
        }

        let proposedSize = sizeForAttachment(attachment)
        let finalSize = efficientImageSize(with: url, proposedSize: proposedSize)
        let image = richTextImage(with: finalSize, url, attachment)

        let isUsingTemporaryLayoutDimensions = finalSize.height == 0

        // show that something is loading.
        if isUsingTemporaryLayoutDimensions {
            attachment.maxSize = CGSize(width: finalSize.width, height: finalSize.width / 2)
        }
        else {
            attachment.maxSize = CGSize(width: finalSize.width, height: finalSize.height)
        }

        let contentInformation = ContentInformation(isPrivateOnWPCom: isPrivate, isSelfHostedWithCredentials: false)
        let index = mediaArray.count
        let indexPath = IndexPath(row: index, section: 1)
        weak var weakImage = image

        image.loadImage(from: contentInformation, preferedSize: finalSize, indexPath: indexPath, onSuccess: { [weak self] indexPath in
            guard
                let richMedia = self?.mediaArray[indexPath.row],
                let img = weakImage
            else {
                return
            }

            richMedia.attachment.maxSize = img.contentSize()

            if isUsingTemporaryLayoutDimensions {
                self?.layoutAttachmentViews()
            }
        }, onError: { (indexPath, error) in
            DDLogError("\(String(describing: error))")
        })

        let media = RichMedia(image: image, attachment: attachment)
        mediaArray.append(media)

        return image
    }

    /// Retrieves the URL for a link wrapping a text attachment, if one exists.
    ///
    /// - Parameters:
    ///     - attachment: A WPTextAttachment instance.
    ///
    /// - Returns: An NSURL optional.
    ///
    @objc func linkURLForImageAttachment(_ attachment: WPTextAttachment) -> URL? {
        var link: URL?
        let attrText = attributedText
        attrText?.enumerateAttachments { (textAttachment, range) in
            if textAttachment == attachment {
                var effectiveRange = NSRange()
                if let value = attrText?.attribute(.link, at: range.location, longestEffectiveRange: &effectiveRange, in: NSRange(location: 0, length: (attrText?.length)!)) as? URL {
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
    @objc func handleImageTapped(_ sender: WPRichTextImage) {
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

// MARK: - Constants

private extension WPRichContentView {
    struct Constants {
        static let textContainerInset = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 16.0, right: 0.0)
        static let defaultAttachmentHeight = CGFloat(50.0)
        static let photonQuality = 65
    }
}

// MARK: - Rich Media Struct

/// A simple struct used to keep references to a rich text image and its associated attachment.
///
struct RichMedia {
    let image: WPRichTextImage
    let attachment: WPTextAttachment
}

// MARK: - ContentInformation (ImageSourceInformation)

class ContentInformation: ImageSourceInformation {
    var isPrivateOnWPCom: Bool
    var isSelfHostedWithCredentials: Bool

    init(isPrivateOnWPCom: Bool, isSelfHostedWithCredentials: Bool) {
        self.isPrivateOnWPCom = isPrivateOnWPCom
        self.isSelfHostedWithCredentials = isSelfHostedWithCredentials
    }
}

// This is very much based on Aztec.LayoutManager — most of this code is pretty much copy-pasted
// from there and trimmed to only contain the relevant parts.
@objc fileprivate class BlockquoteBackgroundLayoutManager: NSLayoutManager {
    /// Blockquote's Left Border Color
    ///
    let blockquoteBorderColor = UIColor.listIcon

    /// Blockquote's Left Border width
    ///
    let blockquoteBorderWidth: CGFloat = 2

    /// HeadIndent marker
    /// Used to determine whether a given paragraph is a result of `<blockquote>` being parsed by
    /// NSAttributedString.attributedStringFromHTMLString(:_)
    let headIndentMarker: CGFloat = 20

    /// Blockquote Indent
    ///
    let blockquoteIndent: CGFloat = 10

    /// Draws the background, associated to a given Text Range
    ///
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        drawBlockquotes(forGlyphRange: glyphsToShow, at: origin)
    }

    func drawBlockquotes(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        // Draw: Blockquotes
        textStorage.enumerateAttribute(.paragraphStyle, in: characterRange, options: []) { (object, range, stop) in

            guard
                let style = object as? NSParagraphStyle,
                style.headIndent == headIndentMarker,
                style.firstLineHeadIndent == headIndentMarker
                else {
                    return
            }

            let blockquoteGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                let lineCharacters = textStorage.attributedSubstring(from: lineRange).string
                let lineEndsParagraph = lineCharacters.isEndOfParagraph(before: lineCharacters.endIndex)
                let blockquoteRect = self.blockquoteRect(origin: origin, lineRect: rect, lineEndsParagraph: lineEndsParagraph)

                self.drawBlockquote(in: blockquoteRect.integral, with: context)
            }
        }
    }


    /// Returns the Rect in which the Blockquote should be rendered.
    ///
    /// - Parameters:
    ///     - origin: Origin of coordinates
    ///     - lineRect: Line Fragment's Rect
    ///     - blockquoteIndent: Blockquote Indentation Level for the current lineFragment
    ///     - lineEndsParagraph: Indicates if the current blockquote line is the end of a Paragraph
    ///
    /// - Returns: Rect in which we should render the blockquote.
    ///
    private func blockquoteRect(origin: CGPoint, lineRect: CGRect, lineEndsParagraph: Bool) -> CGRect {
        var blockquoteRect = lineRect.offsetBy(dx: origin.x, dy: origin.y)

        let paddingWidth = CGFloat(4) * 0.5 + blockquoteIndent
        blockquoteRect.origin.x += paddingWidth
        blockquoteRect.size.width -= paddingWidth

        // Ref. Issue #645: Cheking if we this a middle line inside a blockquote paragraph
        if lineEndsParagraph {
            blockquoteRect.size.height -= CGFloat(6) * 0.5
        }

        return blockquoteRect
    }


    /// Draws a single Blockquote Line Fragment, in the specified Rectangle, using a given Graphics Context.
    ///
    private func drawBlockquote(in rect: CGRect, with context: CGContext) {
        let borderRect = CGRect(origin: rect.origin, size: CGSize(width: blockquoteBorderWidth, height: rect.height))
        blockquoteBorderColor.setFill()
        context.fill(borderRect)
    }
}

fileprivate extension String {
    func isEndOfParagraph(before index: String.Index) -> Bool {
        assert(index != startIndex)
        return isEndOfParagraph(at: self.index(before: index))
    }

    func isEndOfParagraph(at index: String.Index) -> Bool {
        guard index != endIndex else {
            return true
        }

        let endingRange = index ..< self.index(after: index)
        let endingString = compatibleSubstring(with: endingRange)
        let paragraphSeparators = [String(.carriageReturn), String(.lineFeed), String(.paragraphSeparator)]

        return paragraphSeparators.contains(endingString)
    }
}

extension WPRichContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer == linkTapGestureRecognizer else {
            return true
        }
        let point = touch.location(in: self)
        let characterIndex = self.layoutManager.characterIndex(for: point, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        // handle tap on link
        if let linkAttribute = self.attributedText?.attribute(.link, at: characterIndex, effectiveRange: nil) {
            return linkAttribute is URL
        }

        return false
    }
}
