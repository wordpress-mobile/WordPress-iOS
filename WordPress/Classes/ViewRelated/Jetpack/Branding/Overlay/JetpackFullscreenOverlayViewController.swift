import UIKit

class JetpackFullscreenOverlayViewController: UIViewController {

    // MARK: Variables

    private let config: JetpackFullscreenOverlayConfig

    // MARK: Lazy Views

    private lazy var closeButtonItem: UIBarButtonItem = {
        let closeButton = UIButton()

        let configuration = UIImage.SymbolConfiguration(pointSize: Constants.closeButtonSymbolSize, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.backgroundColor = .quaternarySystemFill

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Constants.closeButtonRadius),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])
        closeButton.layer.cornerRadius = Constants.closeButtonRadius * 0.5

        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)

        return UIBarButtonItem(customView: closeButton)
    }()

    // MARK: Outlets

    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var footnoteLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!

    // MARK: Initializers

    init(with config: JetpackFullscreenOverlayConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        applyStyles()
        setupContent()
        setupColors()
        setupFonts()
        setupButtonInsets()
    }

    // MARK: Helpers

    private func configureNavigationBar() {
        addCloseButtonIfNeeded()

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = Colors.backgroundColor
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }
    }

    private func addCloseButtonIfNeeded() {
        guard config.shouldShowCloseButton else {
            return
        }

        navigationItem.rightBarButtonItem = closeButtonItem
    }

    private func applyStyles() {
        iconImageView.clipsToBounds = false
        switchButton.layer.cornerRadius = Constants.switchButtonCornerRadius
    }

    private func setupContent() {
        iconImageView.image = config.icon
        titleLabel.text = config.title
        subtitleLabel.text = config.subtitle
        footnoteLabel.text = config.footnote
        switchButton.setTitle(config.switchButtonText, for: .normal)
        continueButton.setTitle(config.continueButtonText, for: .normal)
        footnoteLabel.isHidden = config.footnoteIsHidden
        learnMoreButton.isHidden = config.learnMoreButtonIsHidden
        continueButton.isHidden = config.continueButtonIsHidden
        setupLearnMoreButton()
    }

    private func setupColors() {
        view.backgroundColor = Colors.backgroundColor
        footnoteLabel.textColor = Colors.footnoteTextColor
        learnMoreButton.tintColor = Colors.learnMoreButtonTextColor
        switchButton.backgroundColor = Colors.switchButtonBackgroundColor
        switchButton.tintColor = Colors.switchButtonTextColor
        continueButton.tintColor = Colors.continueButtonTextColor
    }

    private func setupFonts() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        footnoteLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        learnMoreButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        switchButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        continueButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
    }

    private func setupButtonInsets() {
        if #available(iOS 15.0, *) {
            // Continue Button
            var continueButtonConfig: UIButton.Configuration = .plain()
            continueButtonConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
                var outgoing = incoming
                outgoing.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
                return outgoing
            })
            continueButtonConfig.contentInsets = Constants.continueButtonContentInsets
            continueButton.configuration = continueButtonConfig

            // Learn More Button
            var learnMoreButtonConfig: UIButton.Configuration = .plain()
            learnMoreButtonConfig.contentInsets = Constants.learnMoreButtonContentInsets
            learnMoreButton.configuration = learnMoreButtonConfig
        } else {
            // Continue Button
            continueButton.contentEdgeInsets = Constants.continueButtonContentEdgeInsets

            // Learn More Button
            learnMoreButton.contentEdgeInsets = Constants.learnMoreButtonContentEdgeInsets
            learnMoreButton.flipInsetsForRightToLeftLayoutDirection()
        }
    }

    private func setupLearnMoreButton() {
        let externalAttachment = NSTextAttachment(image: UIImage.gridicon(.external, size: Constants.externalIconSize).withTintColor(Colors.learnMoreButtonTextColor))
        externalAttachment.bounds = Constants.externalIconBounds
        let attachmentString = NSAttributedString(attachment: externalAttachment)

        let learnMoreText = NSMutableAttributedString(string: "\(Strings.learnMoreButtonText) \u{FEFF}")
        learnMoreText.append(attachmentString)
        learnMoreButton.setAttributedTitle(learnMoreText, for: .normal)
    }

    // MARK: Actions

    @objc private func closeButtonPressed(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }


    @IBAction func switchButtonPressed(_ sender: Any) {
    }

    @IBAction func continueButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func learnMoreButtonPressed(_ sender: Any) {
        guard let url = URL(string: Constants.learnMoreURLString) else {
            return
        }

        let source = "jetpack_overlay_\(config.analyticsSource)"
        let webViewController = WebViewControllerFactory.controller(url: url, source: source)
        let navController = UINavigationController(rootViewController: webViewController)
        present(navController, animated: true)
    }
}

// MARK: Constants

private extension JetpackFullscreenOverlayViewController {
    enum Strings {
        static let learnMoreButtonText = NSLocalizedString("jetpack.fullscreen.overlay.learnMore",
                                                           value: "Learn more at jetpack.com",
                                                           comment: "Title of a button that displays a blog post in a web view.")
    }

    enum Constants {
        static let closeButtonRadius: CGFloat = 30
        static let closeButtonSymbolSize: CGFloat = 16
        static let continueButtonContentInsets = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)
        static let continueButtonContentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        static let learnMoreButtonContentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 24)
        static let learnMoreButtonContentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 24)
        static let externalIconSize = CGSize(width: 16, height: 16)
        static let externalIconBounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        static let switchButtonCornerRadius: CGFloat = 6

        // TODO: Update link
        static let learnMoreURLString = "https://jetpack.com/blog/"
    }

    enum Colors {
        private static let jetpackGreen50 = UIColor.muriel(color: .jetpackGreen, .shade50).lightVariant()
        private static let jetpackGreen30 = UIColor.muriel(color: .jetpackGreen, .shade30).lightVariant()

        static let backgroundColor = UIColor(light: .systemBackground, dark: .muriel(color: .jetpackGreen, .shade100))
        static let footnoteTextColor = UIColor(light: .muriel(color: .gray, .shade50), dark: .muriel(color: .gray, .shade5))
        static let learnMoreButtonTextColor = UIColor(light: jetpackGreen50, dark: jetpackGreen30)
        static let switchButtonBackgroundColor = jetpackGreen50
        static let continueButtonTextColor = UIColor(light: jetpackGreen50, dark: .white)
        static let switchButtonTextColor = UIColor.white
    }
}

fileprivate extension UIColor {
    func lightVariant() -> UIColor {
        return self.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }
}
