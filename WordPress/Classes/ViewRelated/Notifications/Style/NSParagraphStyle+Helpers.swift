import Foundation


extension NSMutableParagraphStyle
{
    convenience init(minimumLineHeight: CGFloat, maximumLineHeight: CGFloat) {
        self.init()
        self.minimumLineHeight = minimumLineHeight
        self.maximumLineHeight = maximumLineHeight
    }
}
