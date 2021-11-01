import UIKit

extension UIEdgeInsets {
    var flippedForRightToLeft: UIEdgeInsets {
        guard UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft else {
            return self
        }

        return flippedForRightToLeftLayoutDirection()
    }

    func flippedForRightToLeftLayoutDirection() -> UIEdgeInsets {
        return UIEdgeInsets(top: top, left: right, bottom: bottom, right: left)
    }
}

extension UIButton {

    @objc func flipInsetsForRightToLeftLayoutDirection() {
        guard userInterfaceLayoutDirection() == .rightToLeft else {
            return
        }
        contentEdgeInsets = contentEdgeInsets.flippedForRightToLeftLayoutDirection()
        imageEdgeInsets = imageEdgeInsets.flippedForRightToLeftLayoutDirection()
        titleEdgeInsets = titleEdgeInsets.flippedForRightToLeftLayoutDirection()
    }

    func verticallyAlignImageAndText(padding: CGFloat = 5) {
        guard let imageView = imageView,
              let titleLabel = titleLabel else {
                  return
              }

        let imageSize = imageView.frame.size
        let titleSize = titleLabel.frame.size
        let totalHeight = imageSize.height + titleSize.height + padding

        imageEdgeInsets = UIEdgeInsets(
            top: -(totalHeight - imageSize.height),
            left: 0,
            bottom: 0,
            right: -titleSize.width
        )

        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageSize.width,
            bottom: -(totalHeight - titleSize.height),
            right: 0
        )
    }

}

// Hack: Since UIEdgeInsets is a struct in ObjC, you can't have methods on it.
// You can't also export top level functions from Swift.
// 🙄
@objc(InsetsHelper)
class _InsetsHelper: NSObject {
    @objc static func flipForRightToLeftLayoutDirection(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        return insets.flippedForRightToLeftLayoutDirection()
    }
}
