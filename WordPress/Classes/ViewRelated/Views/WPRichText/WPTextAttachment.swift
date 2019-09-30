import Foundation
import UIKit
import WordPressUI
import MobileCoreServices

/// An NSTextAttachment for representing remote HTML content such as images, iframes and video.
///
open class WPTextAttachment: NSTextAttachment {
    @objc fileprivate(set) open var identifier: String
    @objc fileprivate(set) open var tagName: String
    @objc fileprivate(set) open var src: String
    @objc open var maxSize = CGSize.zero

    @objc internal(set) open var attributes: [String: String]?
    @objc internal(set) open var html: String?
    @objc internal(set) open var width = CGFloat(0)
    @objc internal(set) open var height = CGFloat(0)

    // Keys used for NSCoding
    fileprivate let identifierKey = "identifier"
    fileprivate let tagNameKey = "tagName"
    fileprivate let srcKey = "src"
    fileprivate let maxSizeKey = "maxSize"
    fileprivate let attributesKey = "attributes"
    fileprivate let htmlKey = "html"
    fileprivate let widthKey = "width"
    fileprivate let heightKey = "height"


    /// Designated initializer.
    ///
    /// - Parameters:
    ///     - tagName: The tag name of the HTML element represented by the attachment.
    ///     - identifier: A string to use as the attachment's identifier. It should be unique in the context of its NSAttributedString.s
    ///     - src: The URL pointing to the remote content represented by the attachment.
    ///
    @objc public init(tagName: String, identifier: String, src: String) {
        self.identifier = identifier
        self.tagName = tagName
        self.src = src

        // Initialize with default image data to prevent placeholder graphics appearing on iOS 13.
        super.init(data: UIImage(color: .basicBackground).pngData(), ofType: kUTTypePNG as String)
    }


    /// For required NSCoding support.
    ///
    required public init?(coder aDecoder: NSCoder) {
        self.identifier = aDecoder.decodeObject(forKey: identifierKey) as! String
        self.tagName = aDecoder.decodeObject(forKey: tagNameKey) as! String
        self.src = aDecoder.decodeObject(forKey: srcKey) as! String
        self.maxSize = aDecoder.decodeCGSize(forKey: maxSizeKey)

        self.attributes = aDecoder.decodeObject(forKey: attributesKey) as? [String: String]
        self.html = aDecoder.decodeObject(forKey: htmlKey) as? String
        self.width = CGFloat(aDecoder.decodeDouble(forKey: widthKey))
        self.height = CGFloat(aDecoder.decodeDouble(forKey: heightKey))

        super.init(coder: aDecoder)
    }


    /// For NSCoding support.
    ///
    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

        aCoder.encode(identifier, forKey: identifierKey)
        aCoder.encode(tagName, forKey: tagNameKey)
        aCoder.encode(src, forKey: srcKey)
        aCoder.encode(maxSize, forKey: maxSizeKey)

        aCoder.encode(attributes, forKey: attributesKey)
        aCoder.encode(html, forKey: htmlKey)
        aCoder.encode(Double(width), forKey: widthKey)
        aCoder.encode(Double(height), forKey: heightKey)
    }


    /// Adjusts the amount of space for the attachment glyph on a line fragment.
    /// Used for clearing text trailing an attachment when align equals .None
    ///
    open override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if textContainer == nil {
            return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        }

        // If max size height or width is zero, make sure the view's size is zero.
        if maxSize.height == 0 || maxSize.width == 0 {
            return CGRect.zero
        }

        let proposedWidth = lineFrag.size.width
        var width = maxSize.width
        var height = maxSize.height

        // There are a few scenarios handled here.
        // 1. When the width is greater than the line fragment width, scale down to fit
        // the available width.
        // 2. When the height is greater than the proposed line height,
        // reserve the full width of the line for the attachment so it can be centered.
        // 3. Other wise when the height is equal to or less than the proposed height
        // just use the max width & height and let the attachment be rendered inline.
        if width > proposedWidth && width != CGFloat.greatestFiniteMagnitude {
            let ratio = width / height
            width = floor(proposedWidth)
            height = floor(width / ratio)

        } else if height > lineFrag.size.height {
            width = proposedWidth
        }

        return CGRect(x: 0.0, y: 0.0, width: width, height: height)
    }

}
