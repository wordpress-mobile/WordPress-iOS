class FloatingActionButton: UIButton {

    convenience init(image: UIImage) {
        self.init(frame: .zero)

        setImage(image, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .accent
        tintColor = .white

        refreshShadow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.width / 2
    }

    private func refreshShadow() {
        layer.shadowColor = UIColor.gray(.shade20).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 3
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
