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
        // This works... okay, but visibly different and worse than the original codepath.
        var mutRange = NSRange()

        return layoutManager
            .lineFragmentRect(forGlyphAt: range.location, effectiveRange: &mutRange)
            .insetBy(dx: textContainerInset.left, dy: 0)


        // This is the original code-path and for a reason beyond my understanding the `firstPosition`
        // and `lastPosition` are returned as `nil` if I override the `layoutManager`.
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
