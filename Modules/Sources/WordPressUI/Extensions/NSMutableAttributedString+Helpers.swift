import Foundation
import UIKit

// MARK: - NSMutableAttributedString Helpers
//
extension NSMutableAttributedString {

    /// Applies a single attribute to the entire string.
    ///
    /// Prefer this over manually constructing an `NSRange` with `NSMakeRange(0, …)`,
    /// which is error-prone when mixing `String.count` (grapheme clusters) with
    /// `NSRange` (UTF-16 code units).
    ///
    public func applyAttribute(_ key: NSAttributedString.Key, value: Any) {
        // swiftlint:disable:next full_range_attributed_string_attribute
        addAttribute(key, value: value, range: NSRange(location: 0, length: length))
    }

    /// Applies a collection of attributes to the entire string.
    ///
    /// Prefer this over manually constructing an `NSRange` with `NSMakeRange(0, …)`,
    /// which is error-prone when mixing `String.count` (grapheme clusters) with
    /// `NSRange` (UTF-16 code units).
    ///
    public func applyAttributes(_ attrs: [NSAttributedString.Key: Any]) {
        // swiftlint:disable:next full_range_attributed_string_attribute
        addAttributes(attrs, range: NSRange(location: 0, length: length))
    }

    /// Applies the specified foreground color to the full length of the receiver.
    ///
    public func applyForegroundColor(_ color: UIColor) {
        applyAttribute(.foregroundColor, value: color)
    }
}
