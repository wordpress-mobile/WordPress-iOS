import Foundation


public class WPDynamicHeightTextView : UITextView
{
    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        let maxWidth = (preferredMaxLayoutWidth != 0) ? preferredMaxLayoutWidth : frame.width
        let maxSize = CGSize(width: maxWidth, height: CGFloat.max)
        let requiredSize = sizeThatFits(maxSize)
        let roundedSize = CGSize(width: round(requiredSize.width), height: round(requiredSize.height))
        
        return roundedSize
    }
}
