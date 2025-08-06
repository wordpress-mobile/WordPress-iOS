import Foundation

/// This is an extension to NSString that provides logic to summarize HTML content,
/// and convert HTML into plain text.
///
extension NSString {
    /// Converts HTML content into plain text by stripping HTML tags and decodinig XML chars.
    /// Transforms the specified string to plain text.  HTML markup is removed and HTML entities are decoded.
    ///
    /// - Returns: The transformed string.
    ///
    @objc
    public func makePlainText() -> String {
        let characterSet = NSCharacterSet.whitespacesAndNewlines

        return strippingHTML()
            .decodingXMLCharacters()
            .trimmingCharacters(in: characterSet)
    }
}
