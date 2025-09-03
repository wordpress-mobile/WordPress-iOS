import Foundation
import WordPressKitObjCUtils

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
    public func wpkit_summarized() -> String {
        let characterSet = CharacterSet(charactersIn: "\n")

        return (self as String).strippingGutenbergContentForExcerpt()
            .strippingShortcodes()
            .makePlainText()
            .trimmingCharacters(in: characterSet)
            .wpkit_stringByEllipsizing(withMaxLength: NSString.PostDerivedSummaryLength, preserveWords: true)
    }
}

private extension String {
    func makePlainText() -> String {
        let characterSet = NSCharacterSet.whitespacesAndNewlines

        return self.wpkit_stringByStrippingHTML()
            .wpkit_stringByDecodingXMLCharacters()
            .trimmingCharacters(in: characterSet)
    }

    /// Creates a new string by stripping all shortcodes from this string.
    ///
    func strippingShortcodes() -> String {
        let pattern = "\\[[^\\]]+\\]"

        return removingMatches(pattern: pattern, options: .caseInsensitive)
    }

    /// This method is the main entry point to generate excerpts for Gutenberg content.
    ///
    func strippingGutenbergContentForExcerpt() -> String {
        return strippingGutenbergGalleries().strippingGutenbergVideoPress()
    }

    /// Strips Gutenberg galleries from strings.
    ///
    func strippingGutenbergGalleries() -> String {
        let pattern = "(?s)<!--\\swp:gallery?(.*?)wp:gallery\\s-->"

        return removingMatches(pattern: pattern, options: .caseInsensitive)
    }

    /// Strips VideoPress references from Gutenberg VideoPress and Video blocks.
    ///
    func strippingGutenbergVideoPress() -> String {
        let pattern = "(?s)\n?<!--\\swp:video.*?(.*?)wp:video.*?\\s-->"

        return removingMatches(pattern: pattern, options: .caseInsensitive)
    }

    /// Creates a new string by removing all matches of the specified regex.
    ///
    func removingMatches(pattern: String, options: NSRegularExpression.Options = []) -> String {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex: NSRegularExpression

        do {
            regex = try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            return self
        }

        return regex.stringByReplacingMatches(in: self, options: .reportCompletion, range: range, withTemplate: "")
    }
}
