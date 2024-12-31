import UIKit
import WordPressUI

final class BloggingRemindersFlowIntroViewController: UIViewController {

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 20
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

    private let tracker: BloggingRemindersTracker
    private let onNextTapped: () -> Void

    init(tracker: BloggingRemindersTracker, onNextTapped: @escaping () -> Void) {
        self.tracker = tracker
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
        let spacer = UIView()
        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            spacer,
            buttonNext
        ])
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(24, after: promptLabel)
    }

    private func configureConstraints() {
        stackView.pinEdges(to: view.safeAreaLayoutGuide, insets: UIEdgeInsets(.all, 24))
        NSLayoutConstraint.activate([
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

private enum Strings {
    static let introTitle = NSLocalizedString("bloggingRemindersPrompt.intro.title", value: "Blogging Reminders", comment: "Title of the Blogging Reminders Settings screen.")
    static let introDescription = NSLocalizedString("bloggingRemindersPrompt.intro.details", value: "Set up your blogging reminders on days you want to post.", comment: "Description on the first screen of the Blogging Reminders Settings flow called aftet post publishing.")
    static let introButtonTitle = NSLocalizedString("bloggingRemindersPrompt.intro.continueButton", value: "Set reminders", comment: "Title of the set goals button in the Blogging Reminders Settings flow.")
}

private enum Images {
    static let celebrationImageName = "reminders-celebration"
}
