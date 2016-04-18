import UIKit

extension UITextField
{
    func nonNilTrimmedText() -> String {
        guard let str = text?.trim() else {
            return ""
        }
        return str
    }
}
