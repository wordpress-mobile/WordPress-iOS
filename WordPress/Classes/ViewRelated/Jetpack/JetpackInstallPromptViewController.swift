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
    var starFieldView: StarFieldView = {
        let config = StarFieldViewConfig(particleImage: JetpackPromptStyles.Stars.particleImage,
                                         starColors: JetpackPromptStyles.Stars.colors)
        let view = StarFieldView(with: config)
        view.layer.masksToBounds = true
        return view
    }()

    var gradientLayer: CALayer = {
        let gradientLayer = CAGradientLayer()

        // Start color is the background color with no alpha because if we use clear it will fade to black
        // instead of just disappearing
        let startColor = JetpackPromptStyles.backgroundColor.withAlphaComponent(0)
        let endColor = JetpackPromptStyles.backgroundColor

        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.locations = [0.0, 0.9]

        return gradientLayer
    }()

    // MARK: - IBOutlets
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var installButton: FancyButton!
    @IBOutlet weak var noThanksButton: FancyButton!
    @IBOutlet weak var learnMoreButton: FancyButton!

    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var lineItemStats: UILabel!
    @IBOutlet weak var lineItemNotifications: UILabel!
    @IBOutlet weak var lineItemAndMore: UILabel!

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

        backgroundView.addSubview(starFieldView)
        backgroundView.layer.addSublayer(gradientLayer)

        WPAnalytics.track(.jetpackInstallPromptShown, properties: [:], blog: blog)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        starFieldView.frame = view.bounds
        gradientLayer.frame = view.bounds
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

    @IBAction func noThanksTapped(_ sender: Any) {
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

        lineItemStats.text = Strings.stats
        lineItemNotifications.text = Strings.notifications
        lineItemAndMore.text = Strings.andMore

        installButton.setTitle(Strings.installButton, for: .normal)
        learnMoreButton.setTitle(Strings.learnMoreButton, for: .normal)
        noThanksButton.setTitle(Strings.noThanksButton, for: .normal)
    }

    private func applyStyles() {
        view.backgroundColor = JetpackPromptStyles.backgroundColor
        backgroundView.backgroundColor = JetpackPromptStyles.backgroundColor

        // Title
        titleLabel.font = JetpackPromptStyles.Title.font
        titleLabel.textColor = JetpackPromptStyles.Title.textColor
        titleLabel.adjustsFontForContentSizeCategory = true

        // Line items
        let lineItems = [lineItemStats, lineItemNotifications, lineItemAndMore]
        for lineItem in lineItems {
            lineItem?.font = JetpackPromptStyles.LineItem.font
            lineItem?.textColor = JetpackPromptStyles.LineItem.textColor
            lineItem?.adjustsFontForContentSizeCategory = true
        }

        // Buttons
        installButton.isPrimary = true
        configure(button: installButton, style: JetpackPromptStyles.installButtonStyle)
        configure(button: noThanksButton, style: JetpackPromptStyles.noThanksButtonStyle)
        configure(button: learnMoreButton, style: JetpackPromptStyles.learnMoreButtonStyle)
    }

    private func configure(button: FancyButton, style: NUXButtonStyle) {
        guard button.isPrimary else {
            button.secondaryNormalBackgroundColor = style.normal.backgroundColor
            button.secondaryNormalBorderColor = style.normal.borderColor
            button.secondaryTitleColor = style.normal.titleColor
            button.secondaryHighlightBackgroundColor = style.highlighted.backgroundColor
            button.secondaryHighlightBorderColor = style.highlighted.borderColor
            return
        }

        button.primaryNormalBackgroundColor = style.normal.backgroundColor
        button.primaryNormalBorderColor = style.normal.borderColor
        button.primaryTitleColor = style.normal.titleColor
        button.primaryHighlightBackgroundColor = style.highlighted.backgroundColor
        button.primaryHighlightBorderColor = style.highlighted.borderColor
    }

    private func configureAccessibility() {
        learnMoreButton.accessibilityHint = Strings.learnMoreButtonHint
        learnMoreButton.accessibilityTraits = .link

        installButton.accessibilityHint = Strings.installButtonHint
        installButton.accessibilityTraits = .button

        noThanksButton.accessibilityHint = Strings.noThanksButtonHint
        noThanksButton.accessibilityTraits = .button

        textStackView.isAccessibilityElement = true
        textStackView.accessibilityLabel = [Strings.title, Strings.stats, Strings.notifications, Strings.andMore].joined(separator: "\n")
    }
}

// MARK: - Notifications
extension NSNotification.Name {
    static let promptInstallJetpack = NSNotification.Name(rawValue: "JetpackPluginInstallPrompt")
}

// MARK: - Localization
private struct Strings {
    static let title = NSLocalizedString("Would you like to install Jetpack?", comment: "Title for the prompt view asking the user if they'd like to install jetpack")

    static let stats = NSLocalizedString("Clear, concise, and actionable site stats about visitors and traffic.", comment: "Label informing the user of the benefits of stats")
    static let notifications = NSLocalizedString("Keep up with your site’s activity, even when you're away from your desk.", comment: "Label informing the user of the benefits of notifications")
    static let andMore = NSLocalizedString("... and more!", comment: "Label, hint there are more features")

    static let learnMoreButton = NSLocalizedString("Learn More", comment: "Button title, opens a webview with more features")
    static let learnMoreButtonHint = NSLocalizedString("Opens Jetpack website for more information.", comment: "VoiceOver accessibility hint, informating the user that the button opens a website with more information")
    static let installButton = NSLocalizedString("Install", comment: "Button title, accepting the install offer")
    static let installButtonHint = NSLocalizedString("Opens the Jetpack installation view.", comment: "VoiceOver accessibility hint, informating the user that the button opens a view that installs Jetpack")
    static let noThanksButton = NSLocalizedString("No Thanks", comment: "Button title, declining the offer")
    static let noThanksButtonHint = NSLocalizedString("Closes the installation prompt.", comment: "VoiceOver accessibility hint, informating the user that the button closes current view")
}

// MARK: - Styles
private struct JetpackPromptStyles {
    static let backgroundColor = UIColor(red: 0.00, green: 0.11, blue: 0.18, alpha: 1.00)

    struct Title {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .semibold)
        static let textColor: UIColor = .white
    }

    struct LineItem {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let textColor: UIColor = .white
    }

    struct Stars {
        static let particleImage = UIImage(named: "jetpack-circle-particle")

        static let colors = [
            UIColor(red: 0.05, green: 0.27, blue: 0.44, alpha: 0.5),
            UIColor(red: 0.64, green: 0.68, blue: 0.71, alpha: 0.5),
            UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 0.5)
        ]
    }
    static let installButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: .white,
                                                                 borderColor: .white,
                                                                 titleColor: Self.backgroundColor),

                                                   highlighted: .init(backgroundColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90),
                                                                      borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90),
                                                                      titleColor: Self.backgroundColor),

                                                   disabled: .init(backgroundColor: .white,
                                                                   borderColor: .white,
                                                                   titleColor: Self.backgroundColor))

    static let noThanksButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: Self.backgroundColor,
                                                                   borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.40),
                                                                   titleColor: .white),

                                                     highlighted: .init(backgroundColor: Self.backgroundColor,
                                                                        borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.20),
                                                                        titleColor: UIColor.white.withAlphaComponent(0.7)),

                                                     disabled: .init(backgroundColor: .white,
                                                                     borderColor: .white,
                                                                     titleColor: Self.backgroundColor))

    static let learnMoreButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: Self.backgroundColor,
                                                                   borderColor: Self.backgroundColor,
                                                                   titleColor: .white),

                                                     highlighted: .init(backgroundColor: Self.backgroundColor,
                                                                        borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.20),
                                                                        titleColor: UIColor.white.withAlphaComponent(0.7)),

                                                     disabled: .init(backgroundColor: .white,
                                                                     borderColor: .white,
                                                                     titleColor: Self.backgroundColor))

}
