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

        updateAppearance()

        NotificationCenter.default
            .addObserver(self, selector: #selector(updateAppearance), name: .appColorDidUpdateAccent, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        layer.cornerRadius = rect.size.width / 2
    }

    @objc
    private func updateAppearance() {
        layer.backgroundColor = UIColor.primary.cgColor
        tintColor = .white

        refreshShadow()
    }

    private func refreshShadow() {
        layer.shadowColor = Constants.shadowColor.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = Constants.shadowRadius
        layer.shadowOpacity = traitCollection.userInterfaceStyle == .light ? 1 : 0
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateAppearance()
    }
}
