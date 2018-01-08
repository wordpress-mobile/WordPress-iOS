import Foundation


// MARK: - String: RegularExpression Helpers
//
extension String {

    /// Find all matches of the specified regex.
    ///
    /// - Parameters:
    ///     - regex: the regex to use.
    ///     - options: the regex options.
    ///
    /// - Returns: the requested matches.
    ///
    func matches(regex: String, options: NSRegularExpression.Options = []) -> [NSTextCheckingResult] {
        let regex = try! NSRegularExpression(pattern: regex, options: options)
        let fullRange = NSRange(location: 0, length: count)

        return regex.matches(in: self, options: [], range: fullRange)
    }

    /// Replaces all matches of a given RegEx, with a template String.
    ///
    /// - Parameters:
    ///     - regex: the regex to use.
    ///     - template: the template string to use for the replacement.
    ///     - options: the regex options.
    ///
    /// - Returns: a new string after replacing all matches with the specified template.
    ///
    func replacingMatches(of regex: String, with template: String, options: NSRegularExpression.Options = []) -> String {

        let regex = try! NSRegularExpression(pattern: regex, options: options)
        let fullRange = NSRange(location: 0, length: count)

        return regex.stringByReplacingMatches(in: self,
                                              options: [],
                                              range: fullRange,
                                              withTemplate: template)
    }

    /// Replaces all matches of a given RegEx using a provided block.
    ///
    /// - Parameters:
    ///     - regex: the regex to use for pattern matching.
    ///     - options: the regex options.
    ///     - block: the block that will be used for the replacement logic.
    ///
    /// - Returns: the new string.
    ///
    func replacingMatches(of regex: String, options: NSRegularExpression.Options = [], using block: (String, [String]) -> String) -> String {

        let regex = try! NSRegularExpression(pattern: regex, options: options)
        let fullRange = NSRange(location: 0, length: count)
        let matches = regex.matches(in: self, options: [], range: fullRange)
        var newString = self

        for match in matches.reversed() {
            let matchRange = range(fromUTF16NSRange: match.range)
            let matchString = String(self[matchRange])

            var submatchStrings = [String]()

            for submatchIndex in 0 ..< match.numberOfRanges {
                let submatchRange = self.range(fromUTF16NSRange: match.range(at: submatchIndex))
                let submatchString = String(self[submatchRange])

                submatchStrings.append(submatchString)
            }

            newString.replaceSubrange(matchRange, with: block(matchString, submatchStrings))
        }

        return newString
    }
}
