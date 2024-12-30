import UIKit
import WordPressUI

final class BloggingRemindersFlowIntroViewController: UIViewController {

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
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.text = Strings.introTitle
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 5
        label.textAlignment = .center
        return label
    }()

    private lazy var buttonNext: UIButton = {
        var configuration = UIButton.Configuration.primary()
        configuration.title = Strings.introButtonTitle

        return UIButton(configuration: configuration, primaryAction: .init { [weak self] _ in
            self?.buttonGetStartedTapped()
        })
    }()

    private let blog: Blog
    private let tracker: BloggingRemindersTracker
    private let source: BloggingRemindersTracker.FlowStartSource
    private let onNextTapped: () -> Void

    init(for blog: Blog,
         tracker: BloggingRemindersTracker,
         source: BloggingRemindersTracker.FlowStartSource,
         onNextTapped: @escaping () -> Void) {
        self.blog = blog
        self.tracker = tracker
        self.source = source
        self.onNextTapped = onNextTapped

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(tracker:) instead")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        configureStackView()
        configureConstraints()
        promptLabel.text = Strings.introDescription
    }

    override func viewDidAppear(_ animated: Bool) {
        tracker.screenShown(.main)

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If a parent VC is being dismissed, and this is the last view shown in its navigation controller, we'll assume
        // the flow was interrupted.
        if isBeingDismissedDirectlyOrByAncestor() && navigationController?.viewControllers.last == self {
            tracker.flowDismissed(source: .main)
        }
    }

    // MARK: - View Configuration

    private func configureStackView() {
        view.addSubview(stackView)
        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            buttonNext
        ])
        stackView.setCustomSpacing(Metrics.afterPromptSpacing, after: promptLabel)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMargins.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.top),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -Metrics.edgeMargins.bottom),

            buttonNext.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.getStartedButtonHeight),
            buttonNext.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }

    private func buttonGetStartedTapped() {
        tracker.buttonPressed(button: .continue, screen: .main)
        onNextTapped()
    }
}

extension BloggingRemindersFlowIntroViewController: BloggingRemindersActions {
    @objc private func dismissTapped() {
        dismiss(from: .dismiss, screen: .main, tracker: tracker)
    }
}

// MARK: - Constants

private enum Strings {
    static let introTitle = NSLocalizedString("bloggingRemindersPrompt.intro.title", value: "Blogging Reminders", comment: "Title of the Blogging Reminders Settings screen.")
    static let introDescription = NSLocalizedString("bloggingRemindersPrompt.intro.details", value: "Set up your blogging reminders on days you want to post.", comment: "Description on the first screen of the Blogging Reminders Settings flow called aftet post publishing.")
    static let introButtonTitle = NSLocalizedString("bloggingRemindersPrompt.intro.continueButton", value: "Set reminders", comment: "Title of the set goals button in the Blogging Reminders Settings flow.")
}

private enum Images {
    static let celebrationImageName = "reminders-celebration"
}

private enum Metrics {
    static let edgeMargins = UIEdgeInsets(top: 46, left: 20, bottom: 20, right: 20)
    static let stackSpacing: CGFloat = 20.0
    static let afterPromptSpacing: CGFloat = 24.0
    static let getStartedButtonHeight: CGFloat = 44.0
}
