import Foundation
import UIKit


@objc public enum WPTextAttachmentAlignment: Int {
    case None, Left, Right, Center
}

/// An NSTextAttachment for representing remote HTML content such as images, iframes and video.
///
public class WPTextAttachment: NSTextAttachment
{
    private(set) public var identifier: String
    private(set) public var tagName: String
    private(set) public var src: String
    public var maxSize = CGSizeZero
    public var align = WPTextAttachmentAlignment.None

    internal(set) public var attributes: [String : String]?
    internal(set) public var html: String?
    internal(set) public var width = CGFloat(0)
    internal(set) public var height = CGFloat(0)

    // Keys used for NSCoding
    private let identifierKey = "identifier"
    private let tagNameKey = "tagName"
    private let srcKey = "src"
    private let maxSizeKey = "maxSize"
    private let alignKey = "align"
    private let attributesKey = "attributes"
    private let htmlKey = "html"
    private let widthKey = "width"
    private let heightKey = "height"


    /// Designated initializer.
    ///
    /// - Parameters:
    ///     - tagName: The tag name of the HTML element represented by the attachment.
    ///     - identifier: A string to use as the attachment's identifier. It should be unique in the context of its NSAttributedString.s
    ///     - src: The URL pointing to the remote content represented by the attachment.
    ///
    public init(tagName: String, identifier: String, src: String) {
        self.identifier = identifier
        self.tagName = tagName
        self.src = src

        super.init(data: nil, ofType: nil)
    }


    /// For required NSCoding support.
    ///
    required public init?(coder aDecoder: NSCoder) {
        self.identifier = aDecoder.decodeObjectForKey(identifierKey) as! String
        self.tagName = aDecoder.decodeObjectForKey(tagNameKey) as! String
        self.src = aDecoder.decodeObjectForKey(srcKey) as! String
        self.maxSize = aDecoder.decodeCGSizeForKey(maxSizeKey)
        self.align = WPTextAttachmentAlignment(rawValue: aDecoder.decodeIntegerForKey(alignKey))!

        self.attributes = aDecoder.decodeObjectForKey(attributesKey) as? [String : String]
        self.html = aDecoder.decodeObjectForKey(htmlKey) as? String
        self.width = CGFloat(aDecoder.decodeDoubleForKey(widthKey))
        self.height = CGFloat(aDecoder.decodeDoubleForKey(heightKey))

        super.init(coder: aDecoder)
    }


    /// For NSCoding support.
    ///
    public override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)

        aCoder.encodeObject(identifier, forKey: identifierKey)
        aCoder.encodeObject(tagName, forKey: tagNameKey)
        aCoder.encodeObject(src, forKey: srcKey)
        aCoder.encodeCGSize(maxSize, forKey: maxSizeKey)
        aCoder.encodeInteger(align.rawValue, forKey: alignKey)

        aCoder.encodeObject(attributes, forKey: attributesKey)
        aCoder.encodeObject(html, forKey: htmlKey)
        aCoder.encodeDouble(Double(width), forKey: widthKey)
        aCoder.encodeDouble(Double(height), forKey: heightKey)
    }


    /// Adjusts the amount of space for the attachment glyph on a line fragment.
    /// Used for clearing text trailing an attachment when align equals .None
    ///
    public override func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if align != .None || textContainer == nil {
            return super.attachmentBoundsForTextContainer(textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        }

        // If max size height or width is zero, make sure the view's size is zero.
        if maxSize.height == 0 || maxSize.width == 0 {
            return CGRectZero
        }

        let proposedWidth = lineFrag.size.width
        var width = maxSize.width
        var height = maxSize.height

        if width > proposedWidth {
            // When width is greater than the available width scale down.
            let ratio = width / height
            width = floor(proposedWidth)
            height = floor(width / ratio)

        } else if height > lineFrag.size.height {
            // When the attachment is taller than the line height,
            // reserve the full width for the attachment.  The layout
            // manager will center the attachment
            width = proposedWidth
        }

        return CGRect(x: 0.0, y: 0.0, width: width, height: height)
    }

}
