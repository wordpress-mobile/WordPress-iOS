/// A rounded button with a shadow intended for use as a "Floating Action Button"
class FloatingActionButton: UIButton {

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

        tintColor = .white
        refreshShadow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        layer.cornerRadius = rect.size.width / 2
        layer.backgroundColor = UIColor(light: .label, dark: .systemGray2).cgColor
    }

    private func refreshShadow() {
        layer.shadowColor = Constants.shadowColor.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = Constants.shadowRadius
        layer.shadowOpacity = traitCollection.userInterfaceStyle == .light ? 1 : 0
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshShadow()
    }
}
