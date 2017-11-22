import Foundation
import Social

/// Encapsulates String Helper Methods.
///
extension String {
    /// Returns a String with <A>nchored links
    ///
    func stringWithAnchoredLinks() -> String {
        guard let output = (self as NSString).mutableCopy() as? NSMutableString,
                let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return self
        }

        let range   = NSMakeRange(0, count)
        var offset  = 0

        detector.enumerateMatches(in: self, options: [], range: range) { (result, flags, stop) in
            guard let range = result?.range else {
                return
            }

            let rangeWithOffset = NSMakeRange(range.location + offset, range.length)
            let rawURL          = output.substring(with: rangeWithOffset)
            let anchoredURL     = "<a href=\"\(rawURL)\">\(rawURL)</a>"

            output.replaceCharacters(in: rangeWithOffset, with: anchoredURL)
            offset += anchoredURL.count - rawURL.count
        }

        return output as String
    }

    /// Returns a tuple containing the First Line + Body of the text
    ///
    func splitContentTextIntoSubjectAndBody() -> (subject: String, body: String) {
        let indexOfFirstNewline = rangeOfCharacter(from: CharacterSet.newlines)

#if swift(>=4.0)
        var firstLineOfText = self
        var restOfText = String()

        if let indexOfFirstNewline = indexOfFirstNewline {
            firstLineOfText = String(prefix(upTo: indexOfFirstNewline.lowerBound))
            restOfText = String(self[indexOfFirstNewline.upperBound...])
        }
#else
        let firstLineOfText = indexOfFirstNewline != nil ? substring(to: indexOfFirstNewline!.lowerBound) : self
        let restOfText = indexOfFirstNewline != nil ? substring(from: indexOfFirstNewline!.upperBound) : ""
#endif

        return (firstLineOfText, restOfText)
    }

    /// Returns the current string, preceded by an IMG embed pointing to the given URL
    ///
    func stringByPrependingMediaURL(_ url: String) -> String {
        return "<img src='\(url)' /><br/><br/>" + self
    }
}
