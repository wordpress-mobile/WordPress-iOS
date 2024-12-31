import UIKit
 import WordPressUI

final class BloggingRemindersFlowIntroViewController: UIViewController {
    private let scrollView = UIScrollView()

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "reminders-celebration"))
        imageView.tintColor = .systemYellow
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .title1).withWeight(.semibold)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.text = Strings.introTitle
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 5
        label.textAlignment = .center
        return label
    }()

    private lazy var buttonNext: UIButton = {
        var configuration = UIButton.Configuration.primary()
        configuration.title = Strings.introButtonTitle

        let button = UIButton(configuration: configuration, primaryAction: .init { [weak self] _ in
            self?.buttonContinueTapped()
        })
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()

    private let bottomBarView = BottomToolbarView()

    private let tracker: BloggingRemindersTracker
    private var isOnNextTapped = false
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
        setupBottomBar()

        promptLabel.text = Strings.introDescription

        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init(handler: { [weak self] _ in
            self?.buttonCloseTapped()
        }))
    }

    override func viewDidAppear(_ animated: Bool) {
        tracker.screenShown(.main)

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if !isOnNextTapped {
            tracker.flowDismissed(source: .main)
        }
    }

    // MARK: - View Configuration

    private func setupView() {
        let stackView = UIStackView(axis: .vertical, alignment: .center, spacing: 20, [
            imageView,
            titleLabel,
            promptLabel
        ])
        stackView.setCustomSpacing(8, after: titleLabel)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false

        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        stackView.pinEdges(insets: UIEdgeInsets(.all, 20))
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40).isActive = true

        scrollView.pinEdges()
    }

    private func setupBottomBar() {
        bottomBarView.contentView.addSubview(buttonNext)
        buttonNext.pinEdges()

        bottomBarView.configure(in: self, scrollView: scrollView)
    }

    // MARK: Actions

    private func buttonContinueTapped() {
        tracker.buttonPressed(button: .continue, screen: .main)
        isOnNextTapped = true
        onNextTapped()
    }

    private func buttonCloseTapped() {
        tracker.buttonPressed(button: .dismiss, screen: .main)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

private enum Strings {
    static let introTitle = NSLocalizedString("bloggingRemindersPrompt.intro.title", value: "Blogging Reminders", comment: "Title of the Blogging Reminders Settings screen.")
    static let introDescription = NSLocalizedString("bloggingRemindersPrompt.intro.details", value: "Set up your blogging reminders on days you want to post.", comment: "Description on the first screen of the Blogging Reminders Settings flow called aftet post publishing.")
    static let introButtonTitle = NSLocalizedString("bloggingRemindersPrompt.intro.continueButton", value: "Set Reminders", comment: "Title of the set goals button in the Blogging Reminders Settings flow.")
}
