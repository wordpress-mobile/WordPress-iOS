import Foundation
import WordPressShared

/// This is an extension to NSString that provides logic to summarize HTML content,
/// and convert HTML into plain text.
///
extension NSString {
    /// Create a summary for the post based on the post's content.
    ///
    /// - Returns: A summary for the post.
    ///
    @objc
    public func wpkit_summarized() -> String {
        GutenbergExcerptGenerator.firstParagraph(from: (self as String))
    }

    @objc
    public func wpkit_makePlainText() -> String {
        makePlainText()
    }
}
