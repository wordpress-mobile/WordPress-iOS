import UIKit


extension UITextField {
    @objc public func nonNilTrimmedText() -> String {
        let trimmed = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed ?? ""
    }
}
