import Foundation


extension NSMutableAttributedString {

    /// Applies a collection of Styles to all of the substrings that match a given pattern
    ///
    /// - Parameters:
    ///     - pattern: A Regex pattern that should be used to look up for matches
    ///     - styles: Collection of styles to be applied on the matched strings
    ///
    public func applyStylesToMatchesWithPattern(_ pattern: String, styles: [String: AnyObject]) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
            let range = NSRange(location: 0, length: length)

            regex.enumerateMatches(in: string, options: .reportCompletion, range: range) {
                (result: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

                if let theResult = result {
                    self.addAttributes(styles, range: theResult.range)
                }
            }
        } catch { }
    }
}
