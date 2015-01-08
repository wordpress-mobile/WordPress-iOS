import Foundation


public class WPDynamicHeightTextView : UITextView
{
    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        // Fix: Let's add 1pt extra size. There are few scenarios in which text gets clipped by 1 point
        let bottomPadding: CGFloat = 1
        let maxWidth = (preferredMaxLayoutWidth != 0) ? preferredMaxLayoutWidth : frame.width
        let maxSize = CGSize(width: maxWidth, height: CGFloat.max)
        let requiredSize = sizeThatFits(maxSize)
        let roundedSize = CGSize(width: ceil(requiredSize.width), height: ceil(requiredSize.height) + bottomPadding)
        
        return roundedSize
    }
}
