import Foundation

extension UIView {
    func changeLayoutMargins(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) {
        let top = top ?? layoutMargins.top
        let left = left ?? layoutMargins.left
        let bottom = bottom ?? layoutMargins.bottom
        let right = right ?? layoutMargins.right

        layoutMargins = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}
