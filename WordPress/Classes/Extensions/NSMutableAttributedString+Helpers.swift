import Foundation


extension NSMutableAttributedString
{
    /**
    *  @details     Applies a collection of Styles to all of the substrings that match with a given pattern
    *  @param       pattern     A Regex pattern that should be used to look up for matches
    *  @param       styles      Collection of styles to be applied on the matched strings
    */
    public func applyStylesToMatchesWithPattern(pattern: String, styles: [String: AnyObject]) {
        let regex = NSRegularExpression(pattern: pattern, options: .DotMatchesLineSeparators, error: nil)
        let range = NSRange(location: 0, length: length)
        
        regex?.enumerateMatchesInString(string, options: nil, range: range) {
            (result: NSTextCheckingResult!, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            self.addAttributes(styles, range: result.range)
        }
    }
}
