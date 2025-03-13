import UIKit
import WordPressShared

class OnboardingEnableNotificationsViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    private let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true
        navigationController?.delegate = self

        applyStyles()
        applyLocalization()
        updateContent()

        WPAnalytics.track(.onboardingEnableNotificationsDisplayed)
        UserPersistentStoreFactory.instance().onboardingNotificationsPromptDisplayed = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return [.portrait, .portraitUpsideDown]
    }
}

// MARK: - IBAction's
extension OnboardingEnableNotificationsViewController {
    @IBAction func enableButtonTapped(_ sender: Any) {
        WPAnalytics.track(.onboardingEnableNotificationsEnableTapped)

        InteractiveNotificationsManager.shared.requestAuthorization { authorized in
            DispatchQueue.main.async {
                self.completion()
            }
        }
    }

    @IBAction func skipButtonTapped(_ sender: Any) {
        WPAnalytics.track(.onboardingEnableNotificationsSkipped)
        completion()
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
        titleLabel.textColor = .label

        subTitleLabel.font = .preferredFont(forTextStyle: .title3)
        subTitleLabel.textColor = .secondaryLabel
    }

    func applyLocalization() {
        titleLabel.text = Strings.title
        enableButton.setTitle(Strings.enableButton, for: .normal)
        cancelButton.setTitle(Strings.cancelButton, for: .normal)
    }

    func updateContent() {
        subTitleLabel.text = Strings.subtitle

        // Convert the image view to a UIView and embed it
        let imageView = UIView.embedSwiftUIView(UnifiedPrologueNotificationsContentView())
        imageView.frame.size.width = detailView.frame.width
        detailView.addSubview(imageView)
        imageView.pinSubviewToAllEdges(detailView)
    }
}

// MARK: - Constants / Strings
private struct Strings {
    static let title = NSLocalizedString("Enable Notifications?", comment: "Title of the view, asking the user if they want to enable notifications.")
    static let subtitle = NSLocalizedString("Stay in touch with like and comment notifications.", comment: "Subtitle giving the user more context about why to enable notifications.")
    static let enableButton = NSLocalizedString("Enable Notifications", comment: "Title of button that enables push notifications when tapped")
    static let cancelButton = NSLocalizedString("Not Now", comment: "Title of a button that cancels enabling notifications when tapped")
}
