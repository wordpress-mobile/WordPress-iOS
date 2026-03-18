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

        // Extract content while convering  <br>, <br/>, <br /> to newlines first
        let rawText = String(content[tagEnd.upperBound..<pEnd.lowerBound])
            .replacingOccurrences(of: "<br\\s*/?>", with: " ", options: .regularExpression)

        let range = NSRange(rawText.startIndex..., in: rawText)
        var text = (regex?.stringByReplacingMatches(in: rawText, options: [], range: range, withTemplate: "") ?? rawText)
            .stringByDecodingXMLCharacters()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if text.count > maxLength {
            let truncated = String(text.prefix(maxLength))
            text = truncated.lastIndex(of: " ").map { String(truncated[..<$0]) } ?? truncated
        }

        if text.hasSuffix(".") {
            text = String(text.dropLast())
        }
        return text + "…"
    }
}
