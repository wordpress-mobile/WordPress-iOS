import Foundation


extension UITextView {
    @objc func frameForTextInRange(_ range: NSRange) -> CGRect {
        let firstPosition   = position(from: beginningOfDocument, offset: range.location)
        let lastPosition    = position(from: beginningOfDocument, offset: range.location + range.length)
        let textRange       = self.textRange(from: firstPosition!, to: lastPosition!)
        let textFrame       = firstRect(for: textRange!)

        return textFrame
    }
    
    func wordsCount() -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let filteredWords = words.filter({ (word) -> Bool in
            word != ""
        })
        return filteredWords.count
    }
}
