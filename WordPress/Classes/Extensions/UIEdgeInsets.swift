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
