import UIKit
import WordPressShared


extension UITextField {
    @objc public func nonNilTrimmedText() -> String {
        return text?.trim() ?? ""
    }
}
