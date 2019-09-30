import Foundation

// MARK: - Content summary support

extension UITextView {

    /// Returns a count of valid text characters.
    var characterCount: Int {
        return text.characterCount
    }

    /// Returns a count of words in a given text view.
    var wordCount: UInt {
        return text.wordCount()
    }
}

// MARK: - Objective-C support

@objc
extension UITextView {
    func frameForTextInRange(_ range: NSRange) -> CGRect {
        guard
            let firstPosition   = position(from: beginningOfDocument, offset: range.location),
            let lastPosition    = position(from: beginningOfDocument, offset: range.location + range.length),
            let textRange       = self.textRange(from: firstPosition, to: lastPosition)
            else {
                return .zero
        }

        let textFrame = firstRect(for: textRange)

        return textFrame
    }
}
