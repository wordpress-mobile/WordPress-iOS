import Foundation


// MARK: - String: RegularExpression Helpers
//
extension String {

    /// Replaces all matches of a given RegEx, with a template String.
    ///
    func replaceMatches(of regex: String, with template: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let range = NSRange(location: 0, length: characters.count)
            return regex.stringByReplacingMatches(in: self,
                                                  options: [],
                                                  range: range,
                                                  withTemplate: template)
        } catch {
            assertionFailure()
        }

        return self
    }
}
