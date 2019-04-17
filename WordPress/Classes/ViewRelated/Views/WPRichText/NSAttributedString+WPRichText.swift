import Foundation
import UIKit


/// An extension for creating an NSAttributedString from an HTML formatted string.
/// HTML elements that load remote content (e.g. images or iframes) are represented by WPTextAttachments
///
public extension NSAttributedString {

    /// Create an NSAttributedString from an HTML formatted string.
    ///
    /// - Parameters:
    ///     - string: An HTML formatted string.
    ///     - defaultDocumentAttributes:
    ///
    /// - Throws: See init(data:options:documentAttributes:)
    ///
    /// - Returns: NSAttributedString Optional
    ///
    class func attributedStringFromHTMLString(
        _ string: String,
        defaultAttributes: [NSAttributedString.Key: Any]?) throws -> NSAttributedString? {

        let formatter = WPRichTextFormatter()
        return try formatter.attributedStringFromHTMLString(string, defaultDocumentAttributes: defaultAttributes)
    }

}
