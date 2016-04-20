import Foundation


extension UITextView
{
    func frameForTextInRange(range: NSRange) -> CGRect {
        let firstPosition   = positionFromPosition(beginningOfDocument, offset: range.location)
        let lastPosition    = positionFromPosition(beginningOfDocument, offset: range.location + range.length)
        let textRange       = textRangeFromPosition(firstPosition!, toPosition: lastPosition!)
        let textFrame       = firstRectForRange(textRange!)
        
        return textFrame
    }
}
