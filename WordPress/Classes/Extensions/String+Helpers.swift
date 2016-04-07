import Foundation
import WordPressShared

extension String {
    func stringByDecodingXMLCharacters() -> String {
        return NSString.decodeXMLCharactersIn(self)
    }

    func stringByEncodingXMLCharacters() -> String {
        return NSString.encodeXMLCharactersIn(self)
    }

    /// Returns `self` if not empty, or `nil` otherwise
    func nonEmptyString() -> String? {
        return isEmpty ? nil : self
    }
}
