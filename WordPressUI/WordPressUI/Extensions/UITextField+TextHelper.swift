import UIKit


extension UITextField {
    public func nonNilTrimmedText() -> String {
        let trimmed = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed ?? ""
    }
}
