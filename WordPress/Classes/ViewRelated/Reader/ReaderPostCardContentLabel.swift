import UIKit

@objc public class ReaderPostCardContentLabel: UILabel {
    public override func intrinsicContentSize() -> CGSize {
        var size = super.intrinsicContentSize()
        size.width = ceil(size.width)
        size.height = ceil(size.height) + 1.0
        return size
    }
}
