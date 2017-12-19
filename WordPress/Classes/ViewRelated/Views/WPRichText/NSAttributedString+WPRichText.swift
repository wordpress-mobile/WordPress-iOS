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
    public class func attributedStringFromHTMLString(_ string: String, defaultDocumentAttributes: [NSAttributedStringKey: Any]?) throws -> NSAttributedString? {
        return try WPRichTextFormatter().attributedStringFromHTMLString(string, defaultDocumentAttributes: defaultDocumentAttributes)
    }

}
