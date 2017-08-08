import Foundation


// MARK: - String: RegularExpression Helpers
//
extension String {

    /// Replaces all matches of a given RegEx, with a template String.
    ///
    func stringByReplacingMatches(of regex: String, with template: String, options: NSRegularExpression.Options = []) -> String {

        let regex = try! NSRegularExpression(pattern: regex, options: options)
        let fullRange = NSRange(location: 0, length: characters.count)

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
    func stringByReplacingMatches(of regex: String, with options: NSRegularExpression.Options = [], using block: (String, [String]) -> String) -> String {

        let regex = try! NSRegularExpression(pattern: regex, options: options)
        let fullRange = NSRange(location: 0, length: characters.count)
        let matches = regex.matches(in: self, options: [], range: fullRange)
        var newString = self

        for match in matches.reversed() {
            let matchRange = range(from: match.range)
            let matchString = substring(with: matchRange)

            var submatchStrings = [String]()

            for submatchIndex in 0 ..< match.numberOfRanges {
                let submatchRange = self.range(from: match.rangeAt(submatchIndex))
                let submatchString = self.substring(with: submatchRange)

                submatchStrings.append(submatchString)
            }

            newString.replaceSubrange(matchRange, with: block(matchString, submatchStrings))
        }

        return newString
    }
}
