import UIKit

struct ReaderSortingActionSheetOption {
    let title: String
    let image: UIImage
    let checked: Bool
    let identifier: String
    let sortingOption: ReaderSortingOption

    init(title: String, image: UIImage, checked: Bool, identifier: String, sortingOption: ReaderSortingOption) {
        self.title = title
        self.image = image
        self.checked = checked
        self.identifier = identifier
        self.sortingOption = sortingOption
    }
}

class ReaderSortingActionSheetOptionControl: ClosureControl {
    enum Constants {
        static let iconsHeight: CGFloat = 24.0
        static let iconsWidth: CGFloat = 24.0
        static let iconLeading: CGFloat = 16.0
        static let labelLeading: CGFloat = 6.0
        static let minimalTappableHeight: CGFloat = 44.0
        // TODO: check if we should color from assets or from hex
        static let checkTintColor: UIColor = UIColor(light: UIColor(named: "Blue50") ?? UIColor(hexString: "2271B1"), dark: UIColor(named: "Blue30") ?? UIColor(hexString: "5198D9"))
        // TODO: check if we can use iOS system colors here
        static let iconTintColor: UIColor = UIColor(light: UIColor(hexString: "4D4D4D"), dark: UIColor(hexString: "BFBFBF"))
        static let labelColor: UIColor = UIColor(light: .black, dark: .white)
    }

    private lazy var checkView: UIImageView = {
        let view = UIImageView()
        view.image = .gridicon(.checkmark)
        view.tintColor = Constants.checkTintColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.tintColor = Constants.iconTintColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var label: UILabel = {
        let view = UILabel()
        view.textColor = Constants.labelColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private(set) var option: ReaderSortingOption = .noSorting

    override var isSelected: Bool {
        didSet {
            checkView.isHidden = !isSelected
        }
    }

    // MARK: - setup

    convenience init(option: ReaderSortingActionSheetOption, closure: @escaping () -> Void) {
        self.init(frame: CGRect.zero, minimalTappableHeight: Constants.minimalTappableHeight, closure: closure)

        self.option = option.sortingOption
        isSelected = option.checked
        imageView.image = option.image
        label.text = option.title
        accessibilityIdentifier = option.identifier
        accessibilityLabel = option.identifier
        accessibilityHint = option.sortingOption.accessibilityHint
    }

    override init(frame: CGRect, minimalTappableHeight: CGFloat?, closure: @escaping () -> Void) {
        super.init(frame: frame, minimalTappableHeight: minimalTappableHeight, closure: closure)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(checkView)
        addSubview(imageView)
        addSubview(label)

        NSLayoutConstraint.activate([
            checkView.heightAnchor.constraint(equalToConstant: Constants.iconsHeight),
            checkView.widthAnchor.constraint(equalToConstant: Constants.iconsWidth),
            imageView.heightAnchor.constraint(equalToConstant: Constants.iconsHeight),
            imageView.widthAnchor.constraint(equalToConstant: Constants.iconsWidth),
            checkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.leadingAnchor.constraint(equalTo: checkView.trailingAnchor, constant: Constants.iconLeading),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: Constants.labelLeading),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            checkView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            checkView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])
    }
}

class ReaderSortingOptionViewController: UIViewController {
    enum Constants {
        static let gripHeight: CGFloat = 5.0
        static let cornerRadius: CGFloat = 8.0
        static let minimumWidth: CGFloat = 300.0
        static let top: CGFloat = 32.0
        static let bottom: CGFloat = 32.0
        static let leading: CGFloat = 16.0
        static let trailing: CGFloat = 16.0

        enum Stack {
            static let spacing: CGFloat = 24.0
        }
    }

    private let options: [ReaderSortingOption]
    private let preselectedOption: ReaderSortingOption
    private let optionChanged: ((ReaderSortingOption) -> Void)?

    private lazy var gripButton: UIButton = {
        let button = GripButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.headline)
        label.text = NSLocalizedString("Sort by", comment: "Sorting bottom sheet header title")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var optionViews: [ReaderSortingActionSheetOptionControl] = {
        return options.compactMap({ (option) -> ReaderSortingActionSheetOptionControl? in
            guard let image = option.image, let title = option.localizedDescription else {
                return nil
            }
            // TODO: what should be the accessibility label/identifer for the bottom sheet options?
            return ReaderSortingActionSheetOptionControl(option: ReaderSortingActionSheetOption(title: title, image: image, checked: option == self.preselectedOption, identifier: title, sortingOption: option)) {
                self.optionSelected(option)
            }
        })
    }()

    // MARK: - init

    init(options: [ReaderSortingOption], preselectedOption: ReaderSortingOption, optionChanged: ((ReaderSortingOption) -> Void)?) {
        self.options = options
        self.preselectedOption = preselectedOption
        self.optionChanged = optionChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - view lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = .basicBackground

        setupContent()
        refreshForTraits()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshForTraits()
    }

    private func refreshForTraits() {
        if presentingViewController?.traitCollection.horizontalSizeClass == .regular && presentingViewController?.traitCollection.verticalSizeClass != .compact {
            gripButton.isHidden = true
        } else {
            gripButton.isHidden = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        return preferredContentSize = CGSize(width: Constants.minimumWidth, height: view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }

    // MARK: - setup

    private func setupContent() {
        let stackView = UIStackView(arrangedSubviews: optionViews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.Stack.spacing
        stackView.axis = .vertical

        view.addSubview(gripButton)
        view.addSubview(headerLabel)
        view.addSubview(stackView)

        let bottomAnchor = stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.bottom)
        bottomAnchor.priority = .defaultHigh

        NSLayoutConstraint.activate([
            gripButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.gripHeight),
            gripButton.heightAnchor.constraint(equalToConstant: Constants.gripHeight),
            gripButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.top),
            headerLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.leading),
            headerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.trailing),
            stackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: Constants.top),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.leading),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.trailing),
            bottomAnchor
        ])
    }

    // MARK: - actions

    @objc func buttonPressed() {
        dismiss(animated: true, completion: nil)
    }

    private func optionSelected(_ option: ReaderSortingOption) {
        for optionView in optionViews {
            optionView.isSelected = option == optionView.option
        }
        optionChanged?(option)
    }
}

class ClosureControl: UIControl {
    private let minimalTappableHeight: CGFloat?
    private let closure: () -> Void

    init(frame: CGRect, minimalTappableHeight: CGFloat?, closure: @escaping () -> Void) {
        self.minimalTappableHeight = minimalTappableHeight
        self.closure = closure
        super.init(frame: frame)
        self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tapped() {
        closure()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let minimalTappableHeight = minimalTappableHeight {
            let offset = max(0.0, (minimalTappableHeight - bounds.height)/2.0)
            let tappableArea = bounds.insetBy(dx: 0, dy: -offset)
            return tappableArea.contains(point)
        }
        return super.point(inside: point, with: event)
    }
}

extension ReaderSortingOption {
    var accessibilityHint: String? {
        switch self {
        case .date:
            return NSLocalizedString("Tap to sort by date", comment: "Accessibility hint for sorting option button.")
        case .popularity:
            return NSLocalizedString("Tap to sort by popularity", comment: "Accessibility hint for sorting option button.")
        case .noSorting:
            return nil
        }
    }
}
