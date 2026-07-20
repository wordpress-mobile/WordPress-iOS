import Foundation

/// A fast excerpt generator that returns the first paragraph of plain text for
/// a Gutenberg post.
public struct GutenbergExcerptGenerator {
    /// Matches an opening `<p>` tag (optionally with attributes), but not other
    /// elements that merely begin with `<p`, such as `<pre>` or `<param>`.
    private static let openingParagraphRegex = try? NSRegularExpression(pattern: "<p(\\s[^>]*)?>", options: [.caseInsensitive])

    /// Matches a run of one or more `<br>` tags, including self-closing and
    /// attributed variants: `<br>`, `<br/>`, `<br />`, `<br class="…">`.
    private static let lineBreakRegex = try? NSRegularExpression(pattern: "(<br\\b[^>]*>)+", options: [.caseInsensitive])

    /// Matches any remaining HTML tag or shortcode.
    private static let tagOrShortcodeRegex = try? NSRegularExpression(pattern: "<[^>]+>|\\[[^\\]]+\\]", options: [])

    /// Whitespace collapsed into single spaces. Excludes U+00A0 (non-breaking
    /// space) so an intentional `&nbsp;` survives into the excerpt.
    private static let collapsibleWhitespace = CharacterSet.whitespacesAndNewlines
        .subtracting(CharacterSet(charactersIn: "\u{00A0}"))

    public static func firstParagraph(from content: String, maxLength: Int = 150) -> String {
        // Find the first real `<p>` element and its matching `</p>`.
        guard let paragraphTag = firstMatch(of: openingParagraphRegex, in: content),
              let pEnd = content.range(of: "</p>", options: .caseInsensitive, range: paragraphTag.upperBound..<content.endIndex) else {
            return ""
        }

        let paragraph = String(content[paragraphTag.upperBound..<pEnd.lowerBound])

        // Convert `<br>` runs to spaces so words don't run together, then remove
        // any remaining tags and shortcodes.
        let withoutBreaks = replacingMatches(of: lineBreakRegex, in: paragraph, withTemplate: " ")
        let stripped = replacingMatches(of: tagOrShortcodeRegex, in: withoutBreaks, withTemplate: "")

        // Decode entities and collapse every whitespace run into a single space,
        // yielding single-line plain text.
        let text = stripped
            .stringByDecodingXMLCharacters()
            .components(separatedBy: collapsibleWhitespace)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        // Truncate if needed.
        if text.count <= maxLength {
            return text
        }

        let truncated = String(text.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "…"
        }
        return truncated + "…"
    }

    /// Returns the range of the first match of `regex` in `string`, or `nil`.
    private static func firstMatch(of regex: NSRegularExpression?, in string: String) -> Range<String.Index>? {
        guard let regex else { return nil }
        let range = NSRange(string.startIndex..., in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else { return nil }
        return Range(match.range, in: string)
    }

    /// Replaces every match of `regex` in `string` with `template`, returning the
    /// original string unchanged when the regex is unavailable.
    private static func replacingMatches(of regex: NSRegularExpression?, in string: String, withTemplate template: String) -> String {
        guard let regex else { return string }
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
    }
}
