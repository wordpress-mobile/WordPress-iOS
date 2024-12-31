import UIKit
import WordPressUI

final class BloggingRemindersFlowIntroViewController: UIViewController {

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "reminders-celebration"))
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

        setupView()
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

    private func setupView() {
        let stackView = UIStackView(axis: .vertical, alignment: .center, spacing: 20, [
            imageView,
            titleLabel,
            promptLabel,
            SpacerView(minHeight: 8),
            buttonNext
        ])
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(24, after: promptLabel)

        view.addSubview(stackView)

        var insets = UIEdgeInsets(.all, 24)
        insets.top = 48

        stackView.pinEdges(to: view.safeAreaLayoutGuide, insets: insets)
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
    static let introButtonTitle = NSLocalizedString("bloggingRemindersPrompt.intro.continueButton", value: "Set Reminders", comment: "Title of the set goals button in the Blogging Reminders Settings flow.")
}
