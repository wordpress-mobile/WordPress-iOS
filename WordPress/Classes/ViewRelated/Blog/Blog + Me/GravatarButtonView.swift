/// a circular image view with an auto-updating gravatar image
class GravatarButtonView: CircularImageView {

    private let tappableWidth: CGFloat

    var adjustView: ((GravatarButtonView) -> Void)?

    override var image: UIImage? {
        didSet {
            adjustView?(self)
        }
    }

    init(tappableWidth: CGFloat) {
        self.tappableWidth = tappableWidth
        super.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let offset = tappableWidth - self.bounds.width

        let tappableArea = bounds.insetBy(dx: -offset, dy: -offset)
        return tappableArea.contains(point)
    }
}


/// Touch animation
extension GravatarButtonView {

    private struct AnimationConfiguration {
        static let startAlpha: CGFloat = 0.5
        static let endAlpha: CGFloat = 1.0
        static let animationDuration: TimeInterval = 0.3
    }
    /// animates the change of opacity from the current value to AnimationConfiguration.endAlpha
    private func restoreAlpha() {
        UIView.animate(withDuration: AnimationConfiguration.animationDuration) {
            self.alpha = AnimationConfiguration.endAlpha
        }
    }

    /// Custom touch animation.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        alpha = AnimationConfiguration.startAlpha
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        restoreAlpha()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        restoreAlpha()
    }
}


/// Border options
extension GravatarButtonView {

    private struct StandardBorder {
        static var color: UIColor {
            if #available(iOS 13, *) {
                return .separator
            }

            return .gray(.shade20)
        }

        static let width = CGFloat(0.5)
    }
    /// sets border color and width to the circular image view. Defaults to StandardBorder values
    func setBorder(color: UIColor = StandardBorder.color, width: CGFloat = StandardBorder.width) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
}
