import Foundation

extension Scanner {
    public func scanQuotedText() -> [String] {
        var scanned = [String]()
        var quote: String?
        let quoteString = "\""
        while self.isAtEnd == false {
            _ = scanUpToString(quoteString)
            _ = scanString(quoteString)
            quote = scanUpToString(quoteString)
            _ = scanString(quoteString)

            if let quoteString = quote, quoteString.isEmpty() == false {
                scanned.append(quoteString as String)
            }
        }
        return scanned
    }
}
