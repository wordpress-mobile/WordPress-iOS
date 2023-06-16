import UIKit

// Temporary converted to Swift silence the compiler warnings that are treated
// as errors in Objective-C files.
final class PostMetaButton: UIButton {
    override var intrinsicContentSize: CGSize {
        var newSize = super.intrinsicContentSize
        newSize.width += (imageEdgeInsets.left + imageEdgeInsets.right)
        newSize.width += (titleEdgeInsets.left + titleEdgeInsets.right)
        return newSize
    }
}
