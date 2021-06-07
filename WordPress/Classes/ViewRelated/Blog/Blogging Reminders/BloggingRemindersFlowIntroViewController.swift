import UIKit


class BloggingRemindersFlowIntroViewController: UIViewController {

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
        let imageView = UIImageView(image: UIImage(named: Images.celebrationImageName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemYellow
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = TextContent.introTitle
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.text = TextContent.introDescription
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let getStartedButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.setTitle(TextContent.introButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
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

    private func calculatePreferredContentSize() {
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
            getStartedButton,
            UIView()
        ])
        stackView.setCustomSpacing(Metrics.afterPromptSpacing, after: promptLabel)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMarginSize),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMarginSize),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMarginSize),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -Metrics.edgeMarginSize),

            getStartedButton.heightAnchor.constraint(equalToConstant: Metrics.getStartedButtonHeight),
            getStartedButton.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    @objc func getStartedTapped() {
        navigationController?.pushViewController(BloggingRemindersFlowSettingsViewController(), animated: true)
    }
}

// MARK: - DrawerPresentable

extension BloggingRemindersFlowIntroViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

// MARK: - ChildDrawerPositionable

extension BloggingRemindersFlowIntroViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .collapsed
    }
}

// MARK: - Constants

private enum TextContent {
    static let introTitle = NSLocalizedString("Set your blogging goals",
                                              comment: "Title of the Blogging Reminders Settings screen.")

    static let introDescription = NSLocalizedString("Your post is publishing... in the meantime, set up your blogging goals to get reminders, and track your progress.",
                                                    comment: "Description on the first screen of the Blogging Reminders Settings flow.")

    static let introButtonTitle = NSLocalizedString("Set goals",
                                                    comment: "Title of the set goals button in the Blogging Reminders Settings flow.")
}

private enum Images {
    static let celebrationImageName = "reminders-celebration"
}

private enum Metrics {
    static let stackSpacing: CGFloat = 20.0
    static let afterPromptSpacing: CGFloat = 24.0
    static let edgeMarginSize: CGFloat = 16.0
    static let getStartedButtonHeight: CGFloat = 44.0
}
