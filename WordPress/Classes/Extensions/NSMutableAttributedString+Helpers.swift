import Foundation


extension NSMutableAttributedString
{
    /**
    *  @details     Applies a collection of Styles to all of the substrings that match a given pattern
    *  @param       pattern     A Regex pattern that should be used to look up for matches
    *  @param       styles      Collection of styles to be applied on the matched strings
    */
    public func applyStylesToMatchesWithPattern(pattern: String, styles: [String: AnyObject]) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .DotMatchesLineSeparators)
            let range = NSRange(location: 0, length: length)

            regex.enumerateMatchesInString(string, options: .ReportCompletion, range: range) {
                (result: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                
                if let theResult = result {
                    self.addAttributes(styles, range: theResult.range)
                }
            }
        } catch { }
    }
}
