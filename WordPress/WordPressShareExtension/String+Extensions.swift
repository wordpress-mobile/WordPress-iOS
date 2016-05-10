import Foundation
import Social

/// Encapsulates String Helper Methods.
///
extension String
{
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
}
