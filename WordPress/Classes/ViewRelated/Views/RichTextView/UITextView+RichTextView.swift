import Foundation

// MARK: - Content summary support

extension UITextView {

    /// Returns a count of words in a given text view.
    var wordCount: UInt {
        return text.wordCount()
    }

    /// Returns a count of text-based characters, excluding whitespace, newlines & control characters.
    var characterCount: Int {
        guard let text = text else {
            return 0
        }
        return text.count
    }
}

// MARK: - Objective-C support

@objc
extension UITextView {
    func frameForTextInRange(_ range: NSRange) -> CGRect {
        let firstPosition   = position(from: beginningOfDocument, offset: range.location)
        let lastPosition    = position(from: beginningOfDocument, offset: range.location + range.length)
        let textRange       = self.textRange(from: firstPosition!, to: lastPosition!)
        let textFrame       = firstRect(for: textRange!)

        return textFrame
    }
}
