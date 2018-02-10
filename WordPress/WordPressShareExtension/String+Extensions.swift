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
            let rawURL = output.substring(with: rangeWithOffset)

            var niceURL: String
            if let urlComps = URLComponents(string: rawURL), let host = urlComps.host {
                niceURL = "\(host)\(urlComps.path)"
            } else {
                niceURL = rawURL
            }

            let anchoredURL     = "<a href=\"\(rawURL)\">\(niceURL)</a>"

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

    /// Creates a WP friendly <img> string based on the provided parameters
    ///
    /// NOTE: Height and width must both be provided in order for them to be inserted into the returned string.
    ///
    /// - Parameters:
    ///   - remoteURL: Complete URL string to the remote image
    ///   - remoteID: Remote image ID
    ///   - height: Height of image. Can be nil unless width is provided
    ///   - width: Width of image. Can be nil unless height is provided
    /// - Returns: <img> element appended to the current string otherwise the current string if the remoteURL param is nil or empty
    ///
    func stringByAppendingMediaURL(remoteURL: String?, remoteID: Int64?, height: Int32?, width: Int32?) -> String {
        guard let remoteURL = remoteURL, !remoteURL.isEmpty else {
            return self
        }

        var returnURLString = "<img class='alignnone size-full"

        if let remoteID = remoteID, remoteID > 0 {
            returnURLString.append(contentsOf: " wp-image-\(remoteID)")
        }
        returnURLString.append(contentsOf: "' src='\(remoteURL)'")

        if let height = height, height > 0,
            let width = width, width > 0 {
            returnURLString.append(contentsOf: " width='\(width)' height='\(height)'")
        }
        returnURLString.append(contentsOf: " />")

        return self + returnURLString + "<br/><br/>"
    }
}
