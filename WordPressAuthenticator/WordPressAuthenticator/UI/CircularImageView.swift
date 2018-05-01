import Foundation


/// UIImageView with a circular shape.
///
class CircularImageView: UIImageView {

    override var frame: CGRect {
        didSet {
            refreshRadius()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshRadius()
    }

    private func refreshRadius() {
        layer.cornerRadius = frame.width * 0.5
        layer.masksToBounds = true
    }
}
