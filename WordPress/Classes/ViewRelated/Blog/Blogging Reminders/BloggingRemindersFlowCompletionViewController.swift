import UIKit


class BloggingRemindersFlowCompletionViewController: UIViewController {

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: Images.bellImageName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemYellow
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = TextContent.completionTitle
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.text = TextContent.completionPrompt
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.text = TextContent.completionUpdateHint
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let doneButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.setTitle(TextContent.doneButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .basicBackground

        configureStackView()
        configureConstraints()

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = stackView.systemLayoutSizeFitting(size)
    }

    // MARK: - View Configuration

    private func configureStackView() {
        view.addSubview(stackView)

        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            hintLabel,
            doneButton,
            UIView()
        ])
        stackView.setCustomSpacing(Metrics.afterHintSpacing, after: hintLabel)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMarginSize),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMarginSize),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMarginSize),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -Metrics.edgeMarginSize),

            doneButton.heightAnchor.constraint(equalToConstant: Metrics.doneButtonHeight),
            doneButton.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    // MARK: - Actions

    @objc func doneButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - DrawerPresentable

extension BloggingRemindersFlowCompletionViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

extension BloggingRemindersFlowCompletionViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .collapsed
    }
}

// MARK: - Constants

private enum TextContent {
    static let completionTitle = NSLocalizedString("All set!", comment: "Title of the completion screen of the Blogging Reminders Settings screen.")

    static let completionPrompt = NSLocalizedString("You'll get reminders to blog X times a week on DAY and DAY.",
                                                    comment: "Description shown on the completion screen of the Blogging Reminders Settings screen.")

    static let completionUpdateHint = NSLocalizedString("You can update this any time via My Site > Site Settings",
                                                        comment: "Prompt shown on the completion screen of the Blogging Reminders Settings screen.")

    static let doneButtonTitle = NSLocalizedString("Done", comment: "Title for a Done button.")
}

private enum Images {
    static let bellImageName = "reminders-bell"
}

private enum Metrics {
    static let stackSpacing: CGFloat = 20.0
    static let doneButtonHeight: CGFloat = 44.0
    static let afterHintSpacing: CGFloat = 24.0
    static let edgeMarginSize: CGFloat = 16.0
}
