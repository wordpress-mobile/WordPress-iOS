/// A view with a label and action button
class EmptyActionView: UIView {

    enum Constants {
        static let labelOffset: CGFloat = -55
        static let buttonLabelSpacing: CGFloat = 20
        static let labelWidth: CGFloat = 320
        static let font = WPStyleGuide.fontForTextStyle(.title2)
    }

    var title: String? {
        set {
            button.setTitle(newValue, for: .normal)
        }
        get {
            return button.title(for: .normal)
        }
    }

    var labelText: String? {
        set {
            label.text = newValue
        }
        get {
            return label.text
        }
    }

    lazy var button: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
        return button
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        WPStyleGuide.configureLabel(label, textStyle: .title3, fontWeight: .semibold)
        return label
    }()

    private let tappedBlock: () -> Void

    private var offsetCenteredLabelContraint: NSLayoutConstraint?
    private var centeredLabelConstraint: NSLayoutConstraint?

    init(tappedButton: @escaping () -> Void) {
        tappedBlock = tappedButton

        super.init(frame: .zero)
        addSubviews([label, button])

        /// A constraint to center the label + button between the center of the full sized sheet view and its' top
        let dimensionBefore = safeAreaLayoutGuide.topAnchor.anchorWithOffset(to: label.bottomAnchor)
        let dimensionAfter = label.bottomAnchor.anchorWithOffset(to: safeAreaLayoutGuide.centerYAnchor)
        offsetCenteredLabelContraint = dimensionBefore.constraint(equalTo: dimensionAfter, constant: Constants.labelOffset)
        centeredLabelConstraint = label.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)

        NSLayoutConstraint.activate([
//            offsetCenteredLabelContraint,
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: Constants.buttonLabelSpacing),
            label.widthAnchor.constraint(equalToConstant: Constants.labelWidth),
            label.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            button.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor)
        ])
    }

    override func updateConstraints() {
        super.updateConstraints()

        centeredLabelConstraint?.isActive = traitCollection.verticalSizeClass == .compact
        offsetCenteredLabelContraint?.isActive = traitCollection.verticalSizeClass != .compact
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsUpdateConstraints()
    }

    @objc func tappedButton() {
        tappedBlock()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
