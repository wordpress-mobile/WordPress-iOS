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

        enum Header {
            static let spacing: CGFloat = 16
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        }

        enum Button {
            static let height: CGFloat = 54
            static let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 35)
            static let titleInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            static let imageTintColor: UIColor = .neutral(.shade30)
            static let font: UIFont = .preferredFont(forTextStyle: .callout)
            static let textColor: UIColor = .text
            static let badgeHorizontalPadding: CGFloat = 10
        }

        enum Stack {
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }

    let buttons: [ActionSheetButton]
    let headerTitle: String

    init(headerTitle: String, buttons: [ActionSheetButton]) {
        self.headerTitle = headerTitle
        self.buttons = buttons
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var gripButton: UIButton = {
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

        let buttonViews = buttons.map({ (buttonInfo) -> UIButton in
            return button(buttonInfo)
        })

        NSLayoutConstraint.activate([
            gripButton.heightAnchor.constraint(equalToConstant: Constants.gripHeight)
        ])

        let buttonConstraints = buttonViews.map { button in
            return button.heightAnchor.constraint(equalToConstant: Constants.Button.height)
        }

        NSLayoutConstraint.activate(buttonConstraints)

        let stackView = UIStackView(arrangedSubviews: [
            gripButton,
            headerLabelView
        ] + buttonViews)

        stackView.setCustomSpacing(Constants.Header.spacing, after: gripButton)
        stackView.setCustomSpacing(Constants.Header.spacing, after: headerLabelView)

        buttonViews.forEach { button in
            stackView.setCustomSpacing(Constants.buttonSpacing, after: button)
        }

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        refreshForTraits()

        view.addSubview(stackView)
        let stackViewConstraints = [
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -Constants.Stack.insets.left),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: Constants.Stack.insets.right),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -Constants.Stack.insets.top),
        ]

        let bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Constants.Stack.insets.bottom)
        bottomAnchor.priority = .defaultHigh

        NSLayoutConstraint.activate(stackViewConstraints + [bottomAnchor])
    }

    private func createButton(_ handler: @escaping () -> Void) -> UIButton {
        let button: UIButton
        if #available(iOS 14.0, *) {
            button = UIButton(type: .custom, primaryAction: UIAction(handler: { _ in handler() }))
        } else {
            button = ClosureButton(frame: .zero, closure: {
                handler()
            })
        }

        button.titleLabel?.font = Constants.Button.font
        button.setTitleColor(Constants.Button.textColor, for: .normal)
        button.imageView?.tintColor = Constants.Button.imageTintColor
        button.setBackgroundImage(UIImage(color: .divider), for: .highlighted)
        button.titleEdgeInsets = Constants.Button.titleInsets
        button.naturalContentHorizontalAlignment = .leading
        button.contentEdgeInsets = Constants.Button.contentInsets
        button.translatesAutoresizingMaskIntoConstraints = false
        button.flipInsetsForRightToLeftLayoutDirection()
        return button
    }

    private func button(_ info: ActionSheetButton) -> UIButton {
        let button = createButton(info.action)

        button.setTitle(info.title, for: .normal)
        button.setImage(info.image, for: .normal)
        button.accessibilityIdentifier = info.identifier

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
        } else {
            gripButton.isHidden = false
            additionalSafeAreaInsets = .zero
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        return preferredContentSize = CGSize(width: Constants.minimumWidth, height: view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }
}
