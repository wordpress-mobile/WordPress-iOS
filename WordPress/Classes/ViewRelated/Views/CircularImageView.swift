import UIKit

// Makes a UIImageView circular. Handy for gravatars
class CircularImageView: UIImageView {
    // custom animation that can ba set to animate the view on tap
    var tapAnimation: ((CircularImageView) -> Void)?

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
    /// Add the custom animation on tap.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let animation = tapAnimation else {
            super.touchesBegan(touches, with: event)
            return
        }
        animation(self)
    }
}
