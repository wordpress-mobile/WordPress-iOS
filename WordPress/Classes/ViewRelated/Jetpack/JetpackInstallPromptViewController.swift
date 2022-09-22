import UIKit
import WordPressAuthenticator

enum JetpackInstallPromptDismissAction {
    case install
    case noThanks
}

protocol JetpackInstallPromptDelegate: AnyObject {
    func jetpackInstallPromptDidDismiss(_ action: JetpackInstallPromptDismissAction)
}

class JetpackInstallPromptViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var textStackView: UIStackView!

    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var installButton: FancyButton!
    @IBOutlet weak var dismissButton: FancyButton!

    private lazy var learnMoreButton: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(target: self, action: #selector(learnMoreButtonTapped))
        navigationItem.rightBarButtonItem = buttonItem
        return buttonItem
    }()

    // MARK: - Properties

    private let blog: Blog
    private let promptSettings: JetpackInstallPromptSettings
    private var coordinator: JetpackInstallCoordinator?

    private weak var delegate: JetpackInstallPromptDelegate?

    // MARK: - Init

    init(blog: Blog,
         promptSettings: JetpackInstallPromptSettings,
         delegate: JetpackInstallPromptDelegate?) {
        self.blog = blog
        self.promptSettings = promptSettings
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        applyStyles()
        localizeText()
        configureAccessibility()

        WPAnalytics.track(.jetpackInstallPromptShown, properties: [:], blog: blog)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }

    // MARK: - Actions

    @IBAction func installTapped(_ sender: Any) {
        coordinator = JetpackInstallCoordinator(
            blog: blog,
            promptType: .installPrompt,
            navigationController: navigationController) { [weak self] in
                guard let self = self else {
                    return
                }

                self.promptSettings.setPromptWasDismissed(true, for: self.blog)
                self.delegate?.jetpackInstallPromptDidDismiss(.install)
            }

        WPAnalytics.track(.jetpackInstallPromptInstallTapped, properties: [:], blog: blog)

        coordinator?.openJetpackRemoteInstall()
    }

    @IBAction func dismissTapped(_ sender: Any) {
        WPAnalytics.track(.jetpackInstallPromptDismissTapped, properties: [:], blog: blog)

        delegate?.jetpackInstallPromptDidDismiss(.noThanks)
        dismiss(animated: true)
    }

    @IBAction func learnMoreButtonTapped(_ sender: Any) {
        WPAnalytics.track(.jetpackInstallPromptLearnMoreTapped, properties: [:], blog: blog)

        guard let url = URL(string: "https://jetpack.com/features/") else {
            return
        }

        let controller = WebViewControllerFactory.controller(url: url, source: "jetpack_prompt")
        let navController = UINavigationController(rootViewController: controller)
        self.present(navController, animated: true)
    }

    // MARK: - Private: Helpers
    private func localizeText() {
        titleLabel.text = Strings.title
        navigationItem.title = Strings.navigationTitle
        descriptionLabel.text = Strings.description

        installButton.setTitle(Strings.installButton, for: .normal)
        dismissButton.setTitle(Strings.dismissButton, for: .normal)
        learnMoreButton.title = Strings.learnMoreButton
    }

    private func applyStyles() {
        WPStyleGuide.configureColors(view: view, tableView: nil)

        titleLabel.font = JetpackPromptStyles.Title.font
        titleLabel.textColor = JetpackPromptStyles.Title.textColor
        titleLabel.adjustsFontForContentSizeCategory = true

        descriptionLabel.font = JetpackPromptStyles.Description.font
        descriptionLabel.textColor = JetpackPromptStyles.Description.textColor
        descriptionLabel.adjustsFontForContentSizeCategory = true

        configureButtons()
    }

    private func configureButtons() {
        installButton.isPrimary = true

        dismissButton.secondaryNormalBorderColor = .clear
        dismissButton.secondaryHighlightBorderColor = .clear
        dismissButton.secondaryTitleColor = JetpackPromptStyles.Button.textColor
        dismissButton.secondaryNormalBackgroundColor = .clear
        dismissButton.secondaryHighlightBackgroundColor = .clear

        learnMoreButton.setTitleTextAttributes([.foregroundColor: JetpackPromptStyles.Button.textColor], for: .normal)
        learnMoreButton.setTitleTextAttributes([.foregroundColor: JetpackPromptStyles.Button.highlightedTextColor], for: .highlighted)
    }

    private func configureAccessibility() {
        learnMoreButton.isAccessibilityElement = true
        learnMoreButton.accessibilityLabel = Strings.learnMoreButton
        learnMoreButton.accessibilityHint = Strings.learnMoreButtonHint
        learnMoreButton.accessibilityTraits = .link

        installButton.isAccessibilityElement = true
        installButton.accessibilityLabel = Strings.installButton
        installButton.accessibilityHint = Strings.installButtonHint
        installButton.accessibilityTraits = .button

        dismissButton.isAccessibilityElement = true
        dismissButton.accessibilityLabel = Strings.dismissButton
        dismissButton.accessibilityHint = Strings.dismissButtonHint
        dismissButton.accessibilityTraits = .button

        textStackView.isAccessibilityElement = true
        textStackView.accessibilityLabel = [Strings.title, Strings.description].joined(separator: "\n")
    }
}

// MARK: - Notifications
extension NSNotification.Name {
    static let promptInstallJetpack = NSNotification.Name(rawValue: "JetpackPluginInstallPrompt")
}

// MARK: - Localization
private struct Strings {
    static let navigationTitle = NSLocalizedString("Jetpack", comment: "Navigation title for Jetpack install prompt")
    static let title = NSLocalizedString("Make WordPress better by installing the Jetpack plugin.", comment: "Title for the prompt view explaining the user why they should install Jetpack plugin.")
    static let description = NSLocalizedString("Get access to all your Jetpack features including Stats, Notifications, Backup, Security and much more by installing the Jetpack plugin for WordPress.", comment: "Label informing the user of the benefits of Jetpack plugin")

    static let learnMoreButton = NSLocalizedString("Learn more", comment: "Navigation button title, opens a webview with more features")
    static let learnMoreButtonHint = NSLocalizedString("Opens Jetpack website for more information.", comment: "VoiceOver accessibility hint, informating the user that the button opens a website with more information")
    static let installButton = NSLocalizedString("Install Jetpack", comment: "Button title, accepting the install offer")
    static let installButtonHint = NSLocalizedString("Opens the Jetpack installation view.", comment: "VoiceOver accessibility hint, informating the user that the button opens a view that installs Jetpack")
    static let dismissButton = NSLocalizedString("Continue without Jetpack", comment: "Button title, declining the offer")
    static let dismissButtonHint = NSLocalizedString("Closes the installation prompt.", comment: "VoiceOver accessibility hint, informating the user that the button closes current view")
}

// MARK: - Styles
private struct JetpackPromptStyles {
    struct Button {
        static let textColor: UIColor = .primary
        static let highlightedTextColor: UIColor = .primaryDark
    }

    struct Title {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .semibold)
        static let textColor: UIColor = .text
    }

    struct Description {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let textColor: UIColor = .text
    }
}
