import Foundation
import WordPressShared

extension String {
    func stringByDecodingXMLCharacters() -> String {
        return NSString.decodeXMLCharacters(in: self)
    }

    func stringByEncodingXMLCharacters() -> String {
        return NSString.encodeXMLCharacters(in: self)
    }

    func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    /// Returns `self` if not empty, or `nil` otherwise
    ///
    func nonEmptyString() -> String? {
        return isEmpty ? nil : self
    }

    /// Returns a string without the character at the specified index.
    /// This is a non-mutating version of `String.remove(at:)`.
    func removing(at index: Index) -> String {
        var copy = self
        copy.remove(at: index)
        return copy
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
