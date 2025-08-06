import Foundation

/// A fast excerpt generator that returns the first paragraph of plain text for
/// a Gutenberg post.
public struct GutenbergExcerptGenerator {
    // Matches HTML tags OR shortcodes
    private static let regex = try? NSRegularExpression(pattern: "<[^>]+>|\\[[^\\]]+\\]", options: [])

    public static func firstParagraph(from content: String, maxLength: Int = 150) -> String {
        // Find first <p> tag content
        guard let pStart = content.range(of: "<p", options: .caseInsensitive),
              let pEnd = content.range(of: "</p>", options: .caseInsensitive, range: pStart.upperBound..<content.endIndex),
              let tagEnd = content.range(of: ">", range: pStart.upperBound..<pEnd.lowerBound) else {
            return ""
        }

        // Extract content
        let rawText = String(content[tagEnd.upperBound..<pEnd.lowerBound])

        // Remove HTML tags AND shortcodes in one pass
        let range = NSRange(rawText.startIndex..., in: rawText)
        let text = (regex?.stringByReplacingMatches(in: rawText, options: [], range: range, withTemplate: "") ?? rawText)
            .stringByDecodingXMLCharacters()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Truncate if needed
        if text.count <= maxLength {
            return text
        }

        let truncated = String(text.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "…"
        }
        return truncated + "…"
    }
}
