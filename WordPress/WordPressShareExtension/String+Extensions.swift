import Foundation
import Social

/// Encapsulates String Helper Methods.
///
extension String {
    func arrayOfTags() -> [String] {
        guard !self.isEmpty else {
            return [String()]
        }

        return self.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }

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

    /// Creates a WP friendly <img> string based on the provided parameters
    ///
    /// NOTE: Height and width must both be provided in order for them to be inserted into the returned string.
    ///
    /// - Parameters:
    ///   - mediaURL: Complete URL string to the remote image
    ///   - uploadID: Upload ID for the image
    ///   - remoteID: Remote image ID
    ///   - height: Height of image. Can be nil unless width is provided
    ///   - width: Width of image. Can be nil unless height is provided
    /// - Returns: <img> element appended to the current string otherwise the current string if the mediaURL param is nil or empty
    ///
    func stringByAppendingMediaURL(mediaURL: String?,
                                   uploadID: String? = nil,
                                   remoteID: Int64? = nil,
                                   height: Int32? = nil,
                                   width: Int32? = nil) -> String {
        guard let mediaURL = mediaURL, !mediaURL.isEmpty else {
            return self
        }

        var returnURLString = "<img"

        if let remoteID = remoteID, remoteID > 0 {
            returnURLString.append(contentsOf: " wp-image-\(remoteID)")
        }
        returnURLString.append(contentsOf: " src='\(mediaURL)' class='size-full'")

        if let uploadID = uploadID {
            returnURLString.append(contentsOf: " data-wp_upload_id='\(uploadID)'")
        }

        if let height = height, height > 0,
            let width = width, width > 0 {
            returnURLString.append(contentsOf: " width='\(width)' height='\(height)'")
        }
        returnURLString.append(contentsOf: " />")

        return self + returnURLString
    }

    /// Returns true if this String consists of digits
    var isNumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
