import Foundation

extension Scanner {
    public func scanQuotedText() -> [String] {
        var allQuotedTextFound = [String]()
        var textRead: String?
        let quoteString = "\""
        while self.isAtEnd == false {
            _ = scanUpToString(quoteString) // scan up to quotation mark
            _ = scanString(quoteString) // skip opening quotation mark
            textRead = scanUpToString(quoteString) // read text up to next quotation mark
            let closingMarkFound = scanString(quoteString) != nil // skip closing quotation mark

            if let quotedTextFound = textRead, quotedTextFound.isEmpty == false, closingMarkFound {
                allQuotedTextFound.append(quotedTextFound as String)
            }
        }

        return allQuotedTextFound
    }
}
