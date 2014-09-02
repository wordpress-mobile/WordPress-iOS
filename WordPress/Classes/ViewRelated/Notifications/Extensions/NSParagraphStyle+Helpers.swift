import Foundation


extension NSMutableParagraphStyle
{
    convenience init(minLineHeight: CGFloat, maxLineHeight: CGFloat, lineBreakMode: NSLineBreakMode, alignment: NSTextAlignment) {
        self.init()
        self.minimumLineHeight  = minLineHeight
        self.maximumLineHeight  = maxLineHeight
        self.lineBreakMode      = lineBreakMode
        self.alignment          = alignment
    }
}
