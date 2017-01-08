import Foundation
import UIKit
import WordPressShared


/// An NSTextAttachment representing a horizontal rule.
///
open class WPHorizontalRuleAttachment: NSTextAttachment {
    /// Designated initializer.
    ///
    /// - Parameters:
    ///     - tagName: The tag name of the HTML element represented by the attachment.
    ///     - identifier: A string to use as the attachment's identifier. It should be unique in the context of its NSAttributedString.s
    ///     - src: The URL pointing to the remote content represented by the attachment.
    ///
    public init() {
        super.init(data: nil, ofType: nil)
    }


    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    /// Adjusts the amount of space for the attachment glyph on a line fragment.
    /// Used for clearing text trailing an attachment when align equals .None
    ///
    open override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        return CGRect(x: 0.0, y: 0.0, width: lineFrag.size.width, height: 1.0)
    }

}
