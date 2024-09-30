import Foundation

/// This is an extension to NSString that provides logic to summarize HTML content,
/// and convert HTML into plain text.
///
extension NSString {

    static let PostDerivedSummaryLength = 150

    /// Create a summary for the post based on the post's content.
    ///
    /// - Returns: A summary for the post.
    ///
    @objc
    public func summarized() -> String {
        let characterSet = CharacterSet(charactersIn: "\n")

        return (self as String).strippingGutenbergContentForExcerpt()
            .strippingShortcodes()
            .makePlainText()
            .trimmingCharacters(in: characterSet)
            .ellipsizing(withMaxLength: NSString.PostDerivedSummaryLength, preserveWords: true)
    }

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
