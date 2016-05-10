import Foundation
import WordPressShared

extension String {
    func stringByDecodingXMLCharacters() -> String {
        return NSString.decodeXMLCharactersIn(self)
    }

    func stringByEncodingXMLCharacters() -> String {
        return NSString.encodeXMLCharactersIn(self)
    }

    func trim() -> String {
        return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

    /// Returns `self` if not empty, or `nil` otherwise
    func nonEmptyString() -> String? {
        return isEmpty ? nil : self
    }

    /// Remove the specified suffix from the string and returns the new string.
    ///
    /// - Parameters:
    ///     - suffix: The suffix to remove.If this is a regular expression it should not include an ending `$`.
    ///
    func trimSuffix(regexp suffix: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "\(suffix)$", options: .CaseInsensitive) {
            return regex.stringByReplacingMatchesInString(self, options: .ReportCompletion, range: NSRange(location: 0, length: self.characters.count), withTemplate: "")
        }
        return self
    }
}
