/// A rounded button with a shadow intended for use as a "Floating Action Button"
class FloatingActionButton: UIButton {

    private var shadowLayer: CALayer?

    private enum Constants {
        static let shadowColor: UIColor = UIColor.gray(.shade20)
        static let shadowRadius: CGFloat = 3
    }

    convenience init(image: UIImage) {
        self.init(frame: .zero)

        setImage(image, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.backgroundColor = UIColor.primary.cgColor
        tintColor = .white
        refreshShadow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        layer.cornerRadius = rect.size.width / 2
    }

    private func refreshShadow() {
        layer.shadowColor = Constants.shadowColor.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = Constants.shadowRadius
        if #available(iOS 12.0, *) {
            layer.shadowOpacity = traitCollection.userInterfaceStyle == .light ? 1 : 0
        } else {
            layer.shadowOpacity = 1
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshShadow()
    }
}
