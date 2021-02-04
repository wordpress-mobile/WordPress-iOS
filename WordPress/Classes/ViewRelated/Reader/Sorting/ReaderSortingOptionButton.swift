import UIKit

extension ReaderSortingOption {

    var localizedDescription: String? {
        // TODO: check if strings are localized
        switch self {
        case .date:
            return NSLocalizedString("Recent", comment: "Sorting option description")
        case .popularity:
            return NSLocalizedString("Popular", comment: "Sorting option description")
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
    var sourceView: UIView {
        return chevronView
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.tintColor = UIColor(light: UIColor(hexString: "4D4D4D"), dark: UIColor(hexString: "BFBFBF"))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var label: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(light: .black, dark: .white)
        view.font = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var chevronView: UIImageView = {
        let view = UIImageView()
        view.image = .gridicon(.chevronDown)
        view.tintColor = UIColor(light: UIColor(hexString: "4D4D4D"), dark: UIColor(hexString: "BFBFBF"))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var sortingOption: ReaderSortingOption? {
        didSet {
            label.text = sortingOption?.localizedDescription
            iconView.image = sortingOption?.image
        }
    }

    // TODO: check how should it behave when touched/highlighted
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1.0
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

    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        // TODO: check if accessibility is set correctly
        accessibilityIdentifier = "Reader sorting option button"
        accessibilityLabel = NSLocalizedString("Sorting option button", comment: "Accessibility label for sorting option button")

        addSubview(iconView)
        addSubview(label)
        addSubview(chevronView)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 24.0),
            iconView.widthAnchor.constraint(equalToConstant: 24.0),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6.0),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16.0),
            chevronView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 6.0),
            chevronView.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            chevronView.heightAnchor.constraint(equalToConstant: 24.0),
            chevronView.widthAnchor.constraint(equalToConstant: 24.0),
        ])
    }
}
