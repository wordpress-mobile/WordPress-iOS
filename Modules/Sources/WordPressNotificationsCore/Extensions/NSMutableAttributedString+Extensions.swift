import Foundation

extension NSAttributedString {
    /// This helper method returns a new NSAttributedString instance, with all of the the leading / trailing newLines
    /// characters removed.
    ///
    func trimNewlines() -> NSAttributedString {
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

extension NSMutableAttributedString {

    /// Applies a collection of attributes to all of quoted substrings
    ///
    /// - Parameters:
    ///     - attributes: Collection of attributes to be applied on the matched strings
    ///
    func applyAttributes(toQuotes attributes: [NSAttributedString.Key: Any]?) {
        guard let attributes else {
            return
        }
        let rawString = self.string
        let scanner = Scanner(string: rawString)
        let quotes = scanner.scanQuotedText()
        quotes.forEach {
            if let itemRange = rawString.range(of: $0) {
                let range = NSRange(itemRange, in: rawString)
                self.addAttributes(attributes, range: range)
            }
        }
    }
}
