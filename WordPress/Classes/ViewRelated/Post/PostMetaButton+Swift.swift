import UIKit

extension PostMetaButton {
    open override var intrinsicContentSize: CGSize {
        var newSize = super.intrinsicContentSize
        newSize.width += (imageEdgeInsets.left + imageEdgeInsets.right)
        newSize.width += (titleEdgeInsets.left + titleEdgeInsets.right)
        return newSize
    }
}
