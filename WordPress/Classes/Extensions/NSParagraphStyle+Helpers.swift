import Foundation


extension NSMutableParagraphStyle
{
    convenience init(minLineHeight: CGFloat, lineBreakMode: NSLineBreakMode, alignment: NSTextAlignment) {
        self.init()
        self.minimumLineHeight  = minLineHeight
        self.lineBreakMode      = lineBreakMode
        self.alignment          = alignment
    }
    
    convenience init(minLineHeight: CGFloat, maxLineHeight: CGFloat, lineBreakMode: NSLineBreakMode, alignment: NSTextAlignment) {
        self.init(minLineHeight: minLineHeight, lineBreakMode: lineBreakMode, alignment: alignment)
        self.maximumLineHeight  = maxLineHeight
    }
}
