import UIKit

// Makes a UIImageView circular. Handy for gravatars
class CircularImageView: UIImageView {
    @objc var shouldRoundCorners: Bool = true {
        didSet {
            let rect = frame
            frame = rect
        }
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override var frame: CGRect {
        didSet {
            refreshRadius()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshRadius()
    }

    fileprivate func refreshRadius() {

        let radius = shouldRoundCorners ? (frame.width * 0.5) : 0
        if layer.cornerRadius != radius {
            layer.cornerRadius = radius
        }
        if layer.masksToBounds != shouldRoundCorners {
            layer.masksToBounds = shouldRoundCorners
        }
    }
}
