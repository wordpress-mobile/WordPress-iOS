import Foundation

extension String {
    ///
    /// Attempts to remove excessive whitespace in text by replacing multiple new lines with just 2.
    /// This first trims whitespace and newlines from the ends
    /// Then normalizes the newlines by replacing {Space}{Newline} with a single newline char
    /// Then it looks for any newlines that are 3 or more and replaces them with 2 newlines.
    /// Then finally it replaces multiple spaces on the same line with a single space.
    ///
    /// Example:
    /// ```
    /// This is the first     line
    ///
    ///
    ///
    ///
    /// This is the last line
    /// ```
    /// Turns into:
    /// ```
    /// This is the first line
    ///
    /// This is the last line
    /// ```
    ///
    func condenseWhitespace() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s\n", with: "\n", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "[\n]{3,}", with: "\n\n", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
    }

    var replacingLastSpaceWithNonBreakingSpace: String {
        if let lastSpace = range(of: " ", options: .backwards, locale: .current) {
            return replacingCharacters(in: lastSpace, with: "\u{00a0}")
        }
        return self
    }

    /// Trims the trailing characters from the string to ensure the resulting string doesn't exceed the provided limit.
    /// If the string is equal to or shorter than the limit, the string is returned without modifications
    /// If the string is longer, the trailing characters are trimmed and replaced with an ellipsis character,
    /// ensuring the length is equal to the limit
    func truncate(with limit: Int) -> String {
        guard count > limit else {
            return self
        }
        let prefix = self.prefix(limit - 1)
        return "\(prefix)…"
    }
}
