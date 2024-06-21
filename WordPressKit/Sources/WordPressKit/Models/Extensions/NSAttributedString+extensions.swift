import Foundation

extension NSAttributedString {
    /// This helper method returns a new NSAttributedString instance, with all of the the leading / trailing newLines
    /// characters removed.
    ///
    @objc public func trimNewlines() -> NSAttributedString {
        guard let trimmed = mutableCopy() as? NSMutableAttributedString else {
            return self
        }

        let characterSet = CharacterSet.newlines

        // Trim: Leading
        var range = (trimmed.string as NSString).rangeOfCharacter(from: characterSet)

        while range.length != 0 && range.location == 0 {
            trimmed.replaceCharacters(in: range, with: String())
            range = (trimmed.string as NSString).rangeOfCharacter(from: characterSet)
        }

        // Trim Trailing
        range = (trimmed.string as NSString).rangeOfCharacter(from: characterSet, options: .backwards)

        while range.length != 0 && NSMaxRange(range) == trimmed.length {
            trimmed.replaceCharacters(in: range, with: String())
            range = (trimmed.string as NSString).rangeOfCharacter(from: characterSet, options: .backwards)
        }

        return trimmed
    }
}
