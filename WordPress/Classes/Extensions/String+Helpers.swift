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

    /// Returns the NSRange instance matching the full string contents.
    ///
    func rangeOfFullString() -> NSRange {
        return NSMakeRange(0, characters.count)
    }

    /// Returns `self` if not empty, or `nil` otherwise
    ///
    func nonEmptyString() -> String? {
        return isEmpty ? nil : self
    }

    /// Remove the specified suffix from the string and returns the new string.
    ///
    /// - Parameter suffix: The suffix to remove. If this is a regular expression it should not include an ending `$`.
    ///
    func trimSuffix(regexp suffix: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "\(suffix)$", options: .caseInsensitive) {
            return regex.stringByReplacingMatches(in: self, options: .reportCompletion, range: NSRange(location: 0, length: self.characters.count), withTemplate: "")
        }
        return self
    }

    /// Returns a string without the character at the specified index.
    /// This is a non-mutating version of `String.remove(at:)`.
    func removing(at index: Index) -> String {
        var copy = self
        copy.remove(at: index)
        return copy
    }
}
