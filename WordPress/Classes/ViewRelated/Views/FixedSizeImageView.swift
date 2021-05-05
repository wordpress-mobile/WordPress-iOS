import Foundation

class FixedSizeImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        return .zero
    }
}
