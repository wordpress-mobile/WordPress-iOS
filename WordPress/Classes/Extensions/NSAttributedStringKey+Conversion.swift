import Foundation
import UIKit


// MARK: - NSAttributedStringKey Helpers
//
extension NSAttributedString.Key {

    /// Converts a collection of NSAttributedString Attributes, with 'NSAttributedStringKey' instances as 'Keys', into an
    /// equivalent collection that uses regular 'String' instances as keys.
    ///
    static func convertToRaw(attributes: [NSAttributedString.Key: Any]) -> [String: Any] {
        var output = [String: Any]()
        for (key, value) in attributes {
            output[key.rawValue] = value
        }

        return output
    }


    /// Converts a collection of NSAttributedString Attributes, with 'String' instances as 'Keys', into an equivalent
    /// collection that uses the new 'NSAttributedStringKey' enum as keys.
    ///
    static func convertFromRaw(attributes: [String: Any]) -> [NSAttributedString.Key: Any] {
        var output = [NSAttributedString.Key: Any]()
        for (key, value) in attributes {
            let wrappedKey = NSAttributedString.Key(key)
            output[wrappedKey] = value
        }

        return output
    }
}
