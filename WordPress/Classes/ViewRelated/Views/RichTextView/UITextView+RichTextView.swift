import Foundation


extension UITextView {
    @objc func frameForTextInRange(_ range: NSRange) -> CGRect {
        let firstPosition   = position(from: beginningOfDocument, offset: range.location)
        let lastPosition    = position(from: beginningOfDocument, offset: range.location + range.length)
        let textRange       = self.textRange(from: firstPosition!, to: lastPosition!)
        let textFrame       = firstRect(for: textRange!)

        return textFrame
    }
}
