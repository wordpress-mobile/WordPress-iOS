import UIKit

extension UIEdgeInsets {
    func flippedForRightToLeftLayoutDirection() -> UIEdgeInsets {
        return UIEdgeInsets(top: top, left: right, bottom: bottom, right: left)
    }
}

extension UIButton {
    func flipInsetsForRightToLeftLayoutDirection() {
        contentEdgeInsets = contentEdgeInsets.flippedForRightToLeftLayoutDirection()
        imageEdgeInsets = imageEdgeInsets.flippedForRightToLeftLayoutDirection()
        titleEdgeInsets = titleEdgeInsets.flippedForRightToLeftLayoutDirection()
    }
}

// Hack: Since UIEdgeInsets is a struct in ObjC, you can't have methods on it.
// You can't also export top level functions from Swift.
// 🙄
@objc(InsetsHelper)
class _InsetsHelper: NSObject {
    static func flipForRightToLeftLayoutDirection(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        return insets.flippedForRightToLeftLayoutDirection()
    }
}
