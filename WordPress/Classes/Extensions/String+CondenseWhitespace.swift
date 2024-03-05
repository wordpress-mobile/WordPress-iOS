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
}
