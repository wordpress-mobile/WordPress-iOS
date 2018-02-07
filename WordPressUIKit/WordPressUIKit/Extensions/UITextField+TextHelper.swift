import UIKit
import WordPressShared


extension UITextField {
    @objc func nonNilTrimmedText() -> String {
        return text?.trim() ?? ""
    }
}
