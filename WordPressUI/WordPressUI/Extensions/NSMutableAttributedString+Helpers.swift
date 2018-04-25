import Foundation


// MARK: - NSMutableAttributedString Helpers
//
extension NSMutableAttributedString {

    /// Applies the specified foreground color to the full length of the receiver.
    ///
    public func applyForegroundColor(_ color: UIColor) {
        let range = NSRange(location: 0, length: length)
        addAttribute(.foregroundColor, value: color, range: range)
    }
}
