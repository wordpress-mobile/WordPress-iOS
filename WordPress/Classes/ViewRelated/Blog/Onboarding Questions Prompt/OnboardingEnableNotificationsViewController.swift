import UIKit

class OnboardingEnableNotificationsViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    let option: OnboardingOption
    let coordinator: OnboardingQuestionsCoordinator

    init(with coordinator: OnboardingQuestionsCoordinator, option: OnboardingOption) {
        self.coordinator = coordinator
        self.option = option

        super.init(nibName: nil, bundle: nil)
    }

    required convenience init?(coder: NSCoder) {
        self.init(with: OnboardingQuestionsCoordinator(), option: .notifications)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true
        navigationController?.delegate = self

        applyStyles()
        applyLocalization()
        updateContent()

        coordinator.notificationsDisplayed(option: option)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return [.portrait, .portraitUpsideDown]
    }
}

// MARK: - IBAction's
extension OnboardingEnableNotificationsViewController {
    @IBAction func enableButtonTapped(_ sender: Any) {
        coordinator.notificationsEnabledTapped(selection: option)
    }

    @IBAction func skipButtonTapped(_ sender: Any) {
        coordinator.notificationsSkipped(selection: option)
    }
}

// MARK: - Trait Collection Handling
extension OnboardingEnableNotificationsViewController {
    func updateContent(for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory

        // Hide the detail image if the text is too large
        detailView.isHidden = contentSize.isAccessibilityCategory
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContent(for: traitCollection)
    }
}

// MARK: - UINavigation Controller Delegate
extension OnboardingEnableNotificationsViewController: UINavigationControllerDelegate {
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return supportedInterfaceOrientations
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        return .portrait
    }
}

// MARK: - Private Helpers
private extension OnboardingEnableNotificationsViewController {
    func applyStyles() {
        navigationController?.navigationBar.isHidden = true

        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        titleLabel.textColor = .text

        subTitleLabel.font = .preferredFont(forTextStyle: .title3)
        subTitleLabel.textColor = .secondaryLabel
    }

    func applyLocalization() {
        titleLabel.text = Strings.title
        enableButton.setTitle(Strings.enableButton, for: .normal)
        cancelButton.setTitle(Strings.cancelButton, for: .normal)
    }

    func updateContent() {
        let text: String
        let notificationContent: UnifiedPrologueNotificationsContent?

        switch option {
        case .stats:
            text = StatsStrings.subTitle
            notificationContent = .init(topElementTitle: StatsStrings.notificationTopTitle,
                                        middleElementTitle: StatsStrings.notificationMiddleTitle,
                                        bottomElementTitle: StatsStrings.notificationBottomTitle,
                                        topImage: "view-milestone-1k",
                                        middleImage: "traffic-surge-icon")
        case .writing:
            text = WritingStrings.subTitle
            notificationContent = nil

        case .notifications, .showMeAround, .skip:
            text = DefaultStrings.subTitle
            notificationContent = nil

        case .reader:
            text = ReaderStrings.subTitle
            notificationContent = .init(topElementTitle: ReaderStrings.notificationTopTitle,
                                        middleElementTitle: ReaderStrings.notificationMiddleTitle,
                                        bottomElementTitle: ReaderStrings.notificationBottomTitle)
        }

        subTitleLabel.text = text

        // Convert the image view to a UIView and embed it
        let imageView = UIView.embedSwiftUIView(UnifiedPrologueNotificationsContentView(notificationContent))
        imageView.frame.size.width = detailView.frame.width
        detailView.addSubview(imageView)
        imageView.pinSubviewToAllEdges(detailView)
    }
}

// MARK: - Constants / Strings
private struct Strings {
    static let title = NSLocalizedString("Enable Notifications?", comment: "Title of the view, asking the user if they want to enable notifications.")
    static let enableButton = NSLocalizedString("Enable Notifications", comment: "Title of button that enables push notifications when tapped")
    static let cancelButton = NSLocalizedString("Not Now", comment: "Title of a button that cancels enabling notifications when tapped")
}

private struct StatsStrings {
    static let subTitle = NSLocalizedString("Know when your site is getting more traffic, new followers, or when it passes a new milestone!", comment: "Subtitle giving the user more context about why to enable notifications.")

    static let notificationTopTitle = NSLocalizedString("Congratulations! Your site passed *1000 all-time* views!", comment: "Example notification content displayed on the Enable Notifications prompt that is personalized based on a users selection. Words marked between * characters will be displayed as bold text.")
    static let notificationMiddleTitle = NSLocalizedString("Your site appears to be getting *more traffic* than usual!", comment: "Example notification content displayed on the Enable Notifications prompt that is personalized based on a users selection. Words marked between * characters will be displayed as bold text.")
    static let notificationBottomTitle = NSLocalizedString("*Johann Brandt* is now following your site!", comment: "Example notification content displayed on the Enable Notifications prompt that is personalized based on a users selection. Words marked between * characters will be displayed as bold text.")
}

private struct WritingStrings {
    static let subTitle = NSLocalizedString("Stay in touch with your audience with like and comment notifications.", comment: "Subtitle giving the user more context about why to enable notifications.")
}

private struct DefaultStrings {
    static let subTitle = NSLocalizedString("Stay in touch with like and comment notifications.", comment: "Subtitle giving the user more context about why to enable notifications.")
}

private struct ReaderStrings {
    static let subTitle = NSLocalizedString("Know when your favorite authors post new content.", comment: "Subtitle giving the user more context about why to enable notifications.")
    static let notificationTopTitle = NSLocalizedString("*Madison Ruiz* added a new post to their site", comment: "Example notification content displayed on the Enable Notifications prompt that is personalized based on a users selection. Words marked between * characters will be displayed as bold text.")
    static let notificationMiddleTitle = NSLocalizedString("You received *50 likes* on your comment", comment: "Example notification content displayed on the Enable Notifications prompt that is personalized based on a users selection. Words marked between * characters will be displayed as bold text.")
    static let notificationBottomTitle = NSLocalizedString("*Johann Brandt* responded to your comment", comment: "Example notification content displayed on the Enable Notifications prompt that is personalized based on a users selection. Words marked between * characters will be displayed as bold text.")
}
