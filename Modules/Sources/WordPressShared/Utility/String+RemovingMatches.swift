import Foundation
import WordPressSharedObjC

extension String {

    /// Creates a new string by removing all matches of the specified regex.
    ///
    func removingMatches(pattern: String, options: NSRegularExpression.Options = []) -> String {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex: NSRegularExpression

        do {
            regex = try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            assertionFailure("Failed to create regex: \(error)")
            return self
        }

        return regex.stringByReplacingMatches(in: self, options: .reportCompletion, range: range, withTemplate: "")
    }
}
