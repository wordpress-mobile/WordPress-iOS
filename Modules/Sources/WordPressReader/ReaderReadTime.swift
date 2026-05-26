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

        // 2. Count characters from scripts that don't put spaces between words
        // (Chinese, Japanese, Thai, etc.), then remove them. Otherwise an unspaced
        // run collapses into a single "word" below, so they are charged per-character
        // in step 4. Hangul is excluded on purpose because Korean uses spaces.
        let unspacedScripts = #/[\p{Han}\p{Hiragana}\p{Katakana}\p{Thai}\p{Lao}\p{Khmer}\p{Myanmar}\p{Tibetan}]/#
        let unspacedCharCount = clean.matches(of: unspacedScripts).count
        clean = clean.replacing(unspacedScripts, with: " ")

        // 3. Count words
        let wordCount = clean.matches(of: #/\b\w+\b/#).count

        // 4. Base reading time (seconds). Unspaced-script characters are charged per
        // character at a rate derived from wpm, approximating one word as ~2 such
        // characters, so the two rates scale together instead of being independent.
        let unspacedCharactersPerMinute = wpm * 2
        var totalSeconds = (Double(wordCount) / wpm) * 60
        totalSeconds += (Double(unspacedCharCount) / unspacedCharactersPerMinute) * 60

        // 5. Image penalty (12s → 3s floor, decreasing per image)
        let imageCount = text.matches(of: #/<img|!\[/#).count
        for i in 0..<imageCount {
            totalSeconds += Double(max(12 - i, 3))
        }

        // 6. Code block penalty (extra half-speed cost for code)
        let codeMatches = text.matches(of: #/```[\s\S]*?```|`[^`]+`/#)
        for match in codeMatches {
            let codeWords = String(match.output).split(separator: " ").count
            totalSeconds += (Double(codeWords) / wpm) * 60
        }

        return max(1, Int((totalSeconds / 60.0).rounded(.up)))
    }
}
