import UIKit

// Makes a UIImageView circular. Handy for gravatars
class CircularImageView: UIImageView {

    var animatesTouch = false

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


/// Touch animation
extension CircularImageView {

    private struct AnimationConfiguration {
        static let startAlpha: CGFloat = 0.5
        static let endAlpha: CGFloat = 1.0
        static let aimationDuration: TimeInterval = 0.3
    }
    /// animates the change of opacity from the current value to AnimationConfiguration.endAlpha
    private func restoreAlpha() {
        UIView.animate(withDuration: AnimationConfiguration.aimationDuration) {
            self.alpha = AnimationConfiguration.endAlpha
        }
    }
    /// Custom touch animation, executed if animatesTouch is set to true.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if animatesTouch {
            alpha = AnimationConfiguration.startAlpha
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if animatesTouch {
            restoreAlpha()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if animatesTouch {
            restoreAlpha()
        }
    }
}
