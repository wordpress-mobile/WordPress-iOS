import Foundation
import WordPressSharedObjC

extension String {
    public func stringByDecodingXMLCharacters() -> String {
        return NSString.decodeXMLCharacters(in: self)
    }

    public func stringByEncodingXMLCharacters() -> String {
        return NSString.encodeXMLCharacters(in: self)
    }

    public func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    /// Returns `self` if not empty, or `nil` otherwise
    ///
    public func nonEmptyString() -> String? {
        return isEmpty ? nil : self
    }

    /// Returns a string without the character at the specified index.
    /// This is a non-mutating version of `String.remove(at:)`.
    public func removing(at index: Index) -> String {
        var copy = self
        copy.remove(at: index)
        return copy
    }

    /// Returns a count of valid text characters.
    /// - Note : This implementation is influenced by `-wordCount` in `NSString+Helpers`.
    public var characterCount: Int {
        var charCount = 0

        if isEmpty == false {
            let textRange = startIndex..<endIndex
            enumerateSubstrings(in: textRange, options: [.byWords, .localized]) { word, _, _, _ in
                let wordLength = word?.count ?? 0
                charCount += wordLength
            }
        }

        return charCount
    }
}

// MARK: - Prefix removal

public extension String {
    /// Removes the given prefix from the string, if exists.
    ///
    /// Calling this method might invalidate any existing indices for use with this string.
    ///
    /// - Parameters:
    ///     - prefix: A possible prefix to remove from this string.
    ///
    mutating func removePrefix(_ prefix: String) {
        if let prefixRange = range(of: prefix), prefixRange.lowerBound == startIndex {
            removeSubrange(prefixRange)
        }
    }

    /// Returns a string with the given prefix removed, if it exists.
    ///
    /// - Parameters:
    ///     - prefix: A possible prefix to remove from this string.
    ///
    func removingPrefix(_ prefix: String) -> String {
        var copy = self
        copy.removePrefix(prefix)
        return copy
    }

    /// Removes the prefix from the string that matches the given pattern, if any.
    ///
    /// Calling this method might invalidate any existing indices for use with this string.
    ///
    /// - Parameters:
    ///     - pattern: The regular expression pattern to search for. Avoid using `^`.
    ///     - options: The options applied to the regular expression during matching.
    ///
    /// - Throws: an error if it the pattern is not a valid regular expression.
    ///
    mutating func removePrefix(pattern: String, options: NSRegularExpression.Options = []) throws {
        let regexp = try NSRegularExpression(pattern: "^\(pattern)", options: options)
        let fullRange = NSRange(location: 0, length: (self as NSString).length)
        if let match = regexp.firstMatch(in: self, options: [], range: fullRange) {
            let matchRange = match.range
            self = (self as NSString).replacingCharacters(in: matchRange, with: "")
        }
    }

    /// Returns a string without the prefix that matches the given pattern, if it exists.
    ///
    /// - Parameters:
    ///     - pattern: The regular expression pattern to search for. Avoid using `^`.
    ///     - options: The options applied to the regular expression during matching.
    ///
    /// - Throws: an error if it the pattern is not a valid regular expression.
    ///
    func removingPrefix(pattern: String, options: NSRegularExpression.Options = []) throws -> String {
        var copy = self
        try copy.removePrefix(pattern: pattern, options: options)
        return copy
    }
}

// MARK: - Suffix removal

public extension String {
    /// Removes the given suffix from the string, if exists.
    ///
    /// Calling this method might invalidate any existing indices for use with this string.
    ///
    /// - Parameters:
    ///     - suffix: A possible suffix to remove from this string.
    ///
    mutating func removeSuffix(_ suffix: String) {
        if let suffixRange = range(of: suffix, options: [.backwards]), suffixRange.upperBound == endIndex {
            removeSubrange(suffixRange)
        }
    }

    /// Returns a string with the given suffix removed, if it exists.
    ///
    /// - Parameters:
    ///     - suffix: A possible suffix to remove from this string.
    ///
    func removingSuffix(_ suffix: String) -> String {
        var copy = self
        copy.removeSuffix(suffix)
        return copy
    }

    /// Removes the suffix from the string that matches the given pattern, if any.
    ///
    /// Calling this method might invalidate any existing indices for use with this string.
    ///
    /// - Parameters:
    ///     - pattern: The regular expression pattern to search for. Avoid using `$`.
    ///     - options: The options applied to the regular expression during matching.
    ///
    /// - Throws: an error if it the pattern is not a valid regular expression.
    ///
    mutating func removeSuffix(pattern: String, options: NSRegularExpression.Options = []) throws {
        let regexp = try NSRegularExpression(pattern: "\(pattern)$", options: options)
        let fullRange = NSRange(location: 0, length: (self as NSString).length)
        if let match = regexp.firstMatch(in: self, options: [], range: fullRange) {
            let matchRange = match.range
            self = (self as NSString).replacingCharacters(in: matchRange, with: "")
        }
    }

    /// Returns a string without the suffix that matches the given pattern, if it exists.
    ///
    /// - Parameters:
    ///     - pattern: The regular expression pattern to search for. Avoid using `$`.
    ///     - options: The options applied to the regular expression during matching.
    ///
    /// - Throws: an error if it the pattern is not a valid regular expression.
    ///
    func removingSuffix(pattern: String, options: NSRegularExpression.Options = []) throws -> String {
        var copy = self
        try copy.removeSuffix(pattern: pattern, options: options)
        return copy
    }
}

extension String {
    ///
    /// Attempts to remove excessive whitespace in text by replacing multiple new lines with just 2.
    /// This first trims whitespace and newlines from the ends
    /// Then normalizes the newlines by replacing {Space}{Newline} with a single newline char
    /// Then it looks for any newlines that are 3 or more and replaces them with 2 newlines.
    /// Then finally it replaces multiple spaces on the same line with a single space.
    ///
    /// Example:
    /// ```
    /// This is the first     line
    ///
    ///
    ///
    ///
    /// This is the last line
    /// ```
    /// Turns into:
    /// ```
    /// This is the first line
    ///
    /// This is the last line
    /// ```
    ///
    public func condenseWhitespace() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s\n", with: "\n", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "[\n]{3,}", with: "\n\n", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
    }

    public var replacingLastSpaceWithNonBreakingSpace: String {
        if let lastSpace = range(of: " ", options: .backwards, locale: .current) {
            return replacingCharacters(in: lastSpace, with: "\u{00a0}")
        }
        return self
    }

    /// Trims the trailing characters from the string to ensure the resulting string doesn't exceed the provided limit.
    /// If the string is equal to or shorter than the limit, the string is returned without modifications
    /// If the string is longer, the trailing characters are trimmed and replaced with an ellipsis character,
    /// ensuring the length is equal to the limit
    public func truncate(with limit: Int) -> String {
        guard count > limit else {
            return self
        }
        let prefix = self.prefix(limit - 1)
        return "\(prefix)…"
    }

    public func arrayOfTags() -> [String] {
        guard !self.isEmpty else {
            return [String()]
        }

        return self.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    /// Returns a Boolean value indicating if this String begins with the provided prefix.
    /// - Parameter prefix: The prefix to check for.
    /// - Parameter options: The string comparison options to use when checking for the prefix.
    public func hasPrefix(_ prefix: String, with options: CompareOptions) -> Bool {
        let fullOptions = options.union([.anchored])
        return range(of: prefix, options: fullOptions) != nil
    }
}

extension String {
    /// Returns a String with <A>nchored links
    ///
    public func stringWithAnchoredLinks() -> String {
        guard let output = (self as NSString).mutableCopy() as? NSMutableString,
                let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return self
        }

        let range = NSMakeRange(0, count)
        var offset = 0

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

            let anchoredURL = "<a href=\"\(rawURL)\">\(niceURL)</a>"

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
    public func stringByAppendingMediaURL(mediaURL: String?,
                                   uploadID: String? = nil,
                                   remoteID: Int64? = nil,
                                   height: Int32? = nil,
                                   width: Int32? = nil) -> String {
        guard let mediaURL, !mediaURL.isEmpty else {
            return self
        }

        var returnURLString = "<img"

        if let remoteID, remoteID > 0 {
            returnURLString.append(contentsOf: " wp-image-\(remoteID)")
        }
        returnURLString.append(contentsOf: " src='\(mediaURL)' class='size-full'")

        if let uploadID {
            returnURLString.append(contentsOf: " data-wp_upload_id='\(uploadID)'")
        }

        if let height, height > 0,
            let width, width > 0 {
            returnURLString.append(contentsOf: " width='\(width)' height='\(height)'")
        }
        returnURLString.append(contentsOf: " />")

        return self + returnURLString
    }
}
