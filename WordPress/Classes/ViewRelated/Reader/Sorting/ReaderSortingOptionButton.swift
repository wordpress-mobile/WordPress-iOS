import UIKit

extension ReaderSortingOption {

    var localizedDescription: String? {
        // TODO: check if strings are localized properly
        switch self {
        case .date:
            return NSLocalizedString("Recent", comment: "Description of the date sorting option in the Discover tab")
        case .popularity:
            return NSLocalizedString("Popular", comment: "Description of the popularity sorting option in the Discover tab")
        case .noSorting:
            return nil
        }
    }

    var image: UIImage? {
        switch self {
        case .date:
            // TODO: use proper icon
            return .gridicon(.calendar)
        case .popularity:
            // TODO: use proper icon
            return .gridicon(.lineGraph)
        case .noSorting:
            return nil
        }
    }
}

class ReaderSortingOptionButton: UIControl {

    enum Constants {
        static let fontSize: CGFloat = 15.0
        static let iconsHeight: CGFloat = 24.0
        static let iconsWidth: CGFloat = 24.0
        static let iconLeading: CGFloat = 16.0
        static let labelLeading: CGFloat = 6.0
        static let top: CGFloat = 16.0
        static let bottom: CGFloat = -16.0
        static let chevronLeading: CGFloat = 6.0
        static let chevronTrailing: CGFloat = -16.0
        // TODO: check if we can use iOS system colors here
        static let iconsTintColor: UIColor = UIColor(light: UIColor(hexString: "4D4D4D"), dark: UIColor(hexString: "BFBFBF"))
        static let labelColor: UIColor = UIColor(light: .black, dark: .white)
        static let isHighlightedAlpha: CGFloat = 0.5
        static let isNotHighlightedAlpha: CGFloat = 1.0
    }

    var sourceView: UIView {
        return chevronView
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.tintColor = Constants.iconsTintColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var label: UILabel = {
        let view = UILabel()
        view.textColor = Constants.labelColor
        view.font = WPFontManager.systemSemiBoldFont(ofSize: Constants.fontSize)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var labelBottomConstraint: NSLayoutConstraint = {
        return label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.bottom)
    }()

    private lazy var chevronView: UIImageView = {
        let view = UIImageView()
        view.image = .gridicon(.chevronDown)
        view.tintColor = Constants.iconsTintColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var sortingOption: ReaderSortingOption = .noSorting {
        didSet {
            bindSortingOption()
        }
    }

    // TODO: check how should it behave when touched/highlighted
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? Constants.isHighlightedAlpha : Constants.isNotHighlightedAlpha
        }
    }

    // MARK: - setup

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(label)
        addSubview(chevronView)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: Constants.iconsHeight),
            iconView.widthAnchor.constraint(equalToConstant: Constants.iconsWidth),
            iconView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Constants.iconLeading),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Constants.labelLeading),
            label.topAnchor.constraint(equalTo: topAnchor, constant: Constants.top),
            labelBottomConstraint,
            chevronView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            chevronView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: Constants.chevronLeading),
            chevronView.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: Constants.chevronTrailing),
            chevronView.heightAnchor.constraint(equalToConstant: Constants.iconsHeight),
            chevronView.widthAnchor.constraint(equalToConstant: Constants.iconsWidth),
        ])

        bindSortingOption()
    }

    private func bindSortingOption() {
        label.text = sortingOption.localizedDescription
        iconView.image = sortingOption.image

        prepareForVoiceOver()
    }

    public func setLabelBottomCompensation(_ compensation: CGFloat) {
        labelBottomConstraint.constant = Constants.bottom + compensation
    }
}

extension ReaderSortingOptionButton: Accessible {
    func prepareForVoiceOver() {
        isAccessibilityElement = true
        iconView.isAccessibilityElement = false
        label.isAccessibilityElement = false
        chevronView.isAccessibilityElement = false

        // TODO: check if accessibility is set correctly
        accessibilityIdentifier = "Reader sorting option button"
        accessibilityLabel = NSLocalizedString("Sorting option", comment: "Accessibility label for sorting option button")
        accessibilityValue = sortingOption.localizedDescription
        accessibilityTraits = UIAccessibilityTraits.button
    }
}
