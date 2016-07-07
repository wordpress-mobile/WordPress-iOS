import Foundation
import Social

/// Encapsulates String Helper Methods.
///
extension String
{
    /// Returns a String with <A>nchored links
    ///
    func stringWithAnchoredLinks() -> String {
        guard let output = (self as NSString).mutableCopy() as? NSMutableString,
                let detector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue) else
        {
            return self
        }

        let range   = NSMakeRange(0, characters.count)
        var offset  = 0

        detector.enumerateMatchesInString(self, options: [], range: range) { (result, flags, stop) in
            guard let range = result?.range else {
                return
            }

            let rangeWithOffset = NSMakeRange(range.location + offset, range.length)
            let rawURL          = output.substringWithRange(rangeWithOffset)
            let anchoredURL     = "<a href=\"\(rawURL)\">\(rawURL)</a>"

            output.replaceCharactersInRange(rangeWithOffset, withString: anchoredURL)
            offset += anchoredURL.characters.count - rawURL.characters.count
        }

        return output as String
    }

    /// Returns a tuple containing the First Line + Body of the text
    ///
    func splitContentTextIntoSubjectAndBody() -> (subject: String, body: String) {
        let indexOfFirstNewline = rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet())
        let firstLineOfText = indexOfFirstNewline != nil ? substringToIndex(indexOfFirstNewline!.startIndex) : self
        let restOfText = indexOfFirstNewline != nil ? substringFromIndex(indexOfFirstNewline!.endIndex) : ""

        return (firstLineOfText, restOfText)
    }

    /// Returns the current string, preceded by an IMG embed pointing to the given URL
    ///
    func stringByPrependingMediaURL(url: String) -> String {
        return "<img src='\(url)' /><br/><br/>" + self
    }
}
