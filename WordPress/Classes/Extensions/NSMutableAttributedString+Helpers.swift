import Foundation


extension NSMutableAttributedString {

    /// Applies a collection of Styles to all of the substrings that match a given pattern
    ///
    /// - Parameters:
    ///     - pattern: A Regex pattern that should be used to look up for matches
    ///     - styles: Collection of styles to be applied on the matched strings
    ///
    @objc public func applyStylesToMatchesWithPattern(_ pattern: String, styles: [NSAttributedStringKey: Any]) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
            let range = NSRange(location: 0, length: length)

            regex.enumerateMatches(in: string, options: .reportCompletion, range: range) { (result, _, _) -> Void in

                if let theResult = result {
                    self.addAttributes(styles, range: theResult.range)
                }
            }
        } catch { }
    }
}
