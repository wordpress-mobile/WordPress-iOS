import UIKit

// Makes a UIImageView circular. Handy for gravatars
class CircularImageView: UIImageView {
    @objc var shouldRoundCorners: Bool = true {
        didSet {
            let rect: CGRect = frame
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
        let shouldRound: Bool = shouldRoundCorners
        let width: CGFloat = frame.width
        let radius: CGFloat = shouldRound ? (width * 0.5) : 0
        if layer.cornerRadius != radius {
            layer.cornerRadius = radius
        }
        if layer.masksToBounds != shouldRound {
            layer.masksToBounds = shouldRound
        }
    }
}
