import UIKit

extension UITextField {
    @objc func nonNilTrimmedText() -> String {
        return text?.trim() ?? ""
    }
}
