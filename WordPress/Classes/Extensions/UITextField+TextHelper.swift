import UIKit

extension UITextField {
    func nonNilTrimmedText() -> String {
        return text?.trim() ?? ""
    }
}
