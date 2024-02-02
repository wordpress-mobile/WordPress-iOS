import WordPressUI

struct ActionSheetButton {
    let title: String
    let image: UIImage
    let identifier: String
    let highlight: Bool
    let badge: UIView?
    let action: () -> Void

    init(title: String, image: UIImage, identifier: String, highlight: Bool = false, badge: UIView? = nil, action: @escaping () -> Void) {
        self.title = title
        self.image = image
        self.identifier = identifier
        self.highlight = highlight
        self.badge = badge
        self.action = action
    }
}

class ActionSheetViewController: UIViewController {

    enum Constants {
        static let gripHeight: CGFloat = 5
        static let cornerRadius: CGFloat = 8
        static let buttonSpacing: CGFloat = 8
        static let additionalSafeAreaInsetsRegular: UIEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        static let minimumWidth: CGFloat = 300
        static let maximumWidth: CGFloat = 600

        enum Header {
            static let spacing: CGFloat = 16
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        }

        enum Button {
            static let height: CGFloat = 54
            static let contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 35)
            static let imagePadding: CGFloat = 16
            static let imageTintColor: UIColor = .neutral(.shade30)
            static let font: UIFont = .preferredFont(forTextStyle: .callout)
            static let textColor: UIColor = .text
            static let badgeHorizontalPadding: CGFloat = 10
        }

        enum Stack {
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }

    let headerView: UIView?
    let buttons: [ActionSheetButton]
    let headerTitle: String
    private weak var scrollView: UIScrollView?
    private var scrollViewHeightConstraint: NSLayoutConstraint?
    private var scrollViewTopConstraint: NSLayoutConstraint?

    init(headerView: UIView? = nil, headerTitle: String, buttons: [ActionSheetButton]) {
        self.headerView = headerView
        self.headerTitle = headerTitle
        self.buttons = buttons
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var gripButton: UIButton = {
        let button = GripButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    @objc func buttonPressed() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = .basicBackground

        let headerLabelView = UIView()
        let headerLabel = UILabel()
        headerLabelView.addSubview(headerLabel)
        headerLabelView.pinSubviewToAllEdges(headerLabel, insets: Constants.Header.insets)

        headerLabel.font = WPStyleGuide.fontForTextStyle(.headline)
        headerLabel.text = headerTitle
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.adjustsFontForContentSizeCategory = true

        let buttonViews = buttons.map({ (buttonInfo) -> UIButton in
            return button(buttonInfo)
        })

        let buttonConstraints = buttonViews.flatMap { button in
            [
                button.heightAnchor.constraint(equalToConstant: Constants.Button.height),
                button.widthAnchor.constraint(equalTo: view.widthAnchor),
            ]
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubviews([gripButton, scrollView])

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        scrollView.addSubview(stackView)
        scrollView.pinSubviewToAllEdges(stackView)

        if let headerView = headerView {
            stackView.addArrangedSubview(headerView)
        }

        stackView.addArrangedSubviews([headerLabelView] + buttonViews)
        stackView.setCustomSpacing(Constants.Header.spacing, after: headerLabelView)

        buttonViews.forEach { button in
            stackView.setCustomSpacing(Constants.buttonSpacing, after: button)
        }

        let topConstraint = scrollView.topAnchor.constraint(equalTo: gripButton.bottomAnchor, constant: Constants.Header.spacing)
        scrollViewTopConstraint = topConstraint
        let secondaryTopConstraint = scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        secondaryTopConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            gripButton.heightAnchor.constraint(equalToConstant: Constants.gripHeight),
            gripButton.widthAnchor.constraint(equalTo: view.widthAnchor),
            gripButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gripButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.Stack.insets.top),
            topConstraint,
            secondaryTopConstraint,
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ] + buttonConstraints)

        self.scrollView = scrollView
        refreshForTraits()
        updateScrollViewHeight()
    }

    private func button(_ info: ActionSheetButton) -> UIButton {
        let button = UIButton(type: .system, primaryAction: UIAction(handler: { _ in info.action() }))

        button.configuration = {
            var configuration = UIButton.Configuration.plain()
            configuration.attributedTitle = {
                var string = AttributedString(info.title)
                string.font = Constants.Button.font
                string.foregroundColor = Constants.Button.textColor
                return string
            }()
            configuration.image = info.image
            configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in
                Constants.Button.imageTintColor
            }
            configuration.imagePadding = Constants.Button.imagePadding
            configuration.contentInsets = Constants.Button.contentInsets
            configuration.background.cornerRadius = 0
            return configuration
        }()
        button.configurationUpdateHandler = { button in
            button.configuration?.background.backgroundColor = button.isHighlighted ? .divider : .clear
        }
        button.contentHorizontalAlignment = .leading
        button.accessibilityIdentifier = info.identifier
        button.translatesAutoresizingMaskIntoConstraints = false

        if let badge = info.badge {
            button.addSubview(badge)
            button.addConstraints([
                badge.constrain(attribute: .left, toAttribute: .right, ofView: button.titleLabel!, relatedBy: .equal, constant: Constants.Button.badgeHorizontalPadding),
                badge.constrainToSuperview(attribute: .centerY, relatedBy: .equal, constant: 0)
            ])
        }

        if info.highlight {
            addSpotlight(to: button)
        }
        return button
    }

    private func addSpotlight(to button: UIButton) {
        let spotlight = QuickStartSpotlightView()
        spotlight.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(spotlight)

        NSLayoutConstraint.activate([
            spotlight.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -Constants.Header.insets.right),
            spotlight.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshForTraits()
    }

    private func refreshForTraits() {
        if presentingViewController?.traitCollection.horizontalSizeClass == .regular && presentingViewController?.traitCollection.verticalSizeClass != .compact {
            gripButton.isHidden = true
            additionalSafeAreaInsets = Constants.additionalSafeAreaInsetsRegular
            scrollViewTopConstraint?.isActive = false
        } else {
            gripButton.isHidden = false
            additionalSafeAreaInsets = .zero
            scrollViewTopConstraint?.isActive = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewHeight()
        let compressedSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let width = min(max(Constants.minimumWidth, compressedSize.width), Constants.maximumWidth)
        preferredContentSize = CGSize(width: width, height: compressedSize.height)
    }

    private func updateScrollViewHeight() {
        guard let scrollView = scrollView else {
            return
        }
        scrollView.layoutIfNeeded()
        let scrollViewHeight = scrollView.contentSize.height
        let heightConstraint = scrollViewHeightConstraint ?? scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: scrollViewHeight)
        heightConstraint.constant = scrollViewHeight
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        scrollViewHeightConstraint = heightConstraint
    }
}
