import Foundation

// MARK: - Content summary support

extension UITextView {

    /// Returns a count of valid text characters.
    var characterCount: Int {
        var charCount = 0

        if !text.isEmpty {
            let textRange = text.startIndex..<text.endIndex
            text.enumerateSubstrings(in: textRange, options: [.byWords, .localized]) { word, _, _, _ in
                let wordLength = word?.count ?? 0
                charCount += wordLength
            }
        }

        return charCount
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
        let firstPosition   = position(from: beginningOfDocument, offset: range.location)
        let lastPosition    = position(from: beginningOfDocument, offset: range.location + range.length)
        let textRange       = self.textRange(from: firstPosition!, to: lastPosition!)
        let textFrame       = firstRect(for: textRange!)

        return textFrame
    }
}
