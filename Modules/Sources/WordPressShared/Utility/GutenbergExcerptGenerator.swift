import Foundation

/// A fast excerpt generator that returns the first paragraph of plain text for
/// a Gutenberg post.
public struct GutenbergExcerptGenerator {
    // Matches HTML tags OR shortcodes
    private static let regex = try? NSRegularExpression(pattern: "<[^>]+>|\\[[^\\]]+\\]", options: [])

    public static func firstParagraph(from content: String, maxLength: Int = 150) -> String {
        // Find the first real <p> tag (not <pre>, <param>, etc.) and its </p>.
        guard let pOpen = content.range(of: "<p(\\s[^>]*)?>", options: [.regularExpression, .caseInsensitive]),
              let pEnd = content.range(of: "</p>", options: .caseInsensitive, range: pOpen.upperBound..<content.endIndex) else {
            return ""
        }

        // Convert <br> runs to spaces so words don't run together.
        let rawText = String(content[pOpen.upperBound..<pEnd.lowerBound])
            .replacingOccurrences(of: "(<br\\b[^>]*>)+", with: " ", options: [.regularExpression, .caseInsensitive])

        let range = NSRange(rawText.startIndex..., in: rawText)
        let text = (regex?.stringByReplacingMatches(in: rawText, options: [], range: range, withTemplate: "") ?? rawText)
            .stringByDecodingXMLCharacters()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

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
