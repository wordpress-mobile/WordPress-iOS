import Foundation

extension String {

    /// Creates a new string by stripping all shortcodes from this string.
    ///
    func strippingShortcodes() -> String {
        let pattern = "\\[[^\\]]+\\]"

        return removingMatches(pattern: pattern, options: .caseInsensitive)
    }
}
