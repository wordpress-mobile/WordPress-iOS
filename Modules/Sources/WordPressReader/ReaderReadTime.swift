import Foundation

public enum ReaderReadTime {
    /// Computes the estimated reading time in minutes from raw post content
    /// (HTML or Markdown), accounting for words, images, and code blocks.
    ///
    /// - Parameters:
    ///   - text: The raw post content (may contain HTML/Markdown).
    ///   - wpm: Words per minute reading speed (default 200).
    /// - Returns: Estimated reading time in minutes (minimum 1).
    public static func compute(_ text: String, wpm: Double = 200) -> Int {
        // 1. Strip HTML & Markdown
        var clean = text
        clean = clean.replacing(#/<[^>]+>/#, with: "")
        clean = clean.replacing(#/!\[.*?\]\(.*?\)/#, with: "")
        clean = clean.replacing(#/\[.*?\]\(.*?\)/#, with: " ")

        // 2. Count words
        let wordCount = clean.matches(of: #/\b\w+\b/#).count

        // 3. Base reading time (seconds)
        var totalSeconds = (Double(wordCount) / wpm) * 60

        // 4. Image penalty (12s → 3s floor, decreasing per image)
        let imageCount = text.matches(of: #/<img|!\[/#).count
        for i in 0..<imageCount {
            totalSeconds += Double(max(12 - i, 3))
        }

        // 5. Code block penalty (extra half-speed cost for code)
        let codeMatches = text.matches(of: #/```[\s\S]*?```|`[^`]+`/#)
        for match in codeMatches {
            let codeWords = String(match.output).split(separator: " ").count
            totalSeconds += (Double(codeWords) / wpm) * 60
        }

        return max(1, Int((totalSeconds / 60.0).rounded(.up)))
    }
}
