import Foundation

extension NSMutableAttributedString {

    /// Applies a collection of attributes to all of quoted substrings
    ///
    /// - Parameters:
    ///     - attributes: Collection of attributes to be applied on the matched strings
    ///
    public func applyAttributes(toQuotes attributes: [NSAttributedString.Key: Any]?) {
        guard let attributes = attributes else {
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
