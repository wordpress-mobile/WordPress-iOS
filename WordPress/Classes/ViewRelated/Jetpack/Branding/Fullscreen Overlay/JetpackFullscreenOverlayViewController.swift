import UIKit
import Lottie

class JetpackFullscreenOverlayViewController: UIViewController {

    // MARK: Variables

    private let viewModel: JetpackFullscreenOverlayViewModel

    /// Sets the animation based on the language orientation
    private var animation: Animation? {
        traitCollection.layoutDirection == .leftToRight ?
        Animation.named(viewModel.animationLtr) :
        Animation.named(viewModel.animationRtl)
    }

    // MARK: Lazy Views

    private var closeButtonImage: UIImage {
        let fontForSystemImage = UIFont.systemFont(ofSize: Metrics.closeButtonRadius)
        let configuration = UIImage.SymbolConfiguration(font: fontForSystemImage)

        // fallback to the gridicon if for any reason the system image fails to render
        return UIImage(systemName: Constants.closeButtonSystemName, withConfiguration: configuration) ??
        UIImage.gridicon(.crossCircle, size: CGSize(width: Metrics.closeButtonRadius, height: Metrics.closeButtonRadius))
    }

    private lazy var closeButtonItem: UIBarButtonItem = {
        let closeButton = CircularImageButton()

        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.tintColor = Colors.closeButtonTintColor
        closeButton.setImageBackgroundColor(UIColor(light: .black, dark: .white))

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonRadius),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])

        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)

        return UIBarButtonItem(customView: closeButton)
    }()

    // MARK: Outlets

    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var footnoteLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var buttonsSuperViewBottomConstraint: NSLayoutConstraint!

    // MARK: Initializers

    init(with viewModel: JetpackFullscreenOverlayViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.isModalInPresentation = true
        configureNavigationBar()
        applyStyles()
        setupConstraints()
        setupContent()
        setupColors()
        setupFonts()
        setupButtonInsets()
        animationView.play()
        viewModel.trackOverlayDisplayed()
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
        guard viewModel.shouldShowCloseButton else {
            return
        }

        navigationItem.rightBarButtonItem = closeButtonItem
    }

    private func applyStyles() {
        switchButton.layer.cornerRadius = Metrics.switchButtonCornerRadius
    }

    private func setupConstraints() {
        // Animation constraint
        let animationSize = animation?.size ?? .init(width: 1, height: 1)
        let ratio = animationSize.width / animationSize.height
        animationView.widthAnchor.constraint(equalTo: animationView.heightAnchor, multiplier: ratio).isActive = true

        // Buttons bottom constraint
        buttonsSuperViewBottomConstraint.constant = viewModel.continueButtonIsHidden ? Metrics.singleButtonBottomSpacing : Metrics.buttonsNormalBottomSpacing
    }

    private func setupContent() {
        animationView.animation = animation
        setTitle()
        subtitleLabel.text = viewModel.subtitle
        footnoteLabel.text = viewModel.footnote
        switchButton.setTitle(viewModel.switchButtonText, for: .normal)
        continueButton.setTitle(viewModel.continueButtonText, for: .normal)
        footnoteLabel.isHidden = viewModel.footnoteIsHidden
        learnMoreButton.isHidden = viewModel.learnMoreButtonIsHidden
        continueButton.isHidden = viewModel.continueButtonIsHidden
        setupLearnMoreButton()
    }

    private func setTitle() {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = Metrics.titleLineHeightMultiple
        style.lineBreakMode = .byTruncatingTail

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: style,
            .kern: Metrics.titleKern
        ]
        let attributedString = NSMutableAttributedString(string: viewModel.title)
        attributedString.addAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedString.length))
        titleLabel.attributedText = attributedString
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
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        footnoteLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        footnoteLabel.adjustsFontForContentSizeCategory = true
        learnMoreButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        switchButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        continueButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
    }

    private func setupButtonInsets() {
        if #available(iOS 15.0, *) {
            // Continue & Switch Buttons
            var buttonConfig: UIButton.Configuration = .plain()
            buttonConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
                var outgoing = incoming
                outgoing.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
                return outgoing
            })
            buttonConfig.contentInsets = Metrics.mainButtonsContentInsets
            continueButton.configuration = buttonConfig
            switchButton.configuration = buttonConfig

            // Learn More Button
            var learnMoreButtonConfig: UIButton.Configuration = .plain()
            learnMoreButtonConfig.contentInsets = Metrics.learnMoreButtonContentInsets
            learnMoreButton.configuration = learnMoreButtonConfig
        } else {
            // Continue Button
            continueButton.contentEdgeInsets = Metrics.mainButtonsContentEdgeInsets

            // Switch Button
            switchButton.contentEdgeInsets = Metrics.mainButtonsContentEdgeInsets

            // Learn More Button
            learnMoreButton.contentEdgeInsets = Metrics.learnMoreButtonContentEdgeInsets
            learnMoreButton.flipInsetsForRightToLeftLayoutDirection()
        }
    }

    private func setupLearnMoreButton() {
        let externalAttachment = NSTextAttachment(image: UIImage.gridicon(.external, size: Metrics.externalIconSize).withTintColor(Colors.learnMoreButtonTextColor))
        externalAttachment.bounds = Metrics.externalIconBounds
        let attachmentString = NSAttributedString(attachment: externalAttachment)

        let learnMoreText = NSMutableAttributedString(string: "\(Strings.learnMoreButtonText) \u{FEFF}")
        learnMoreText.append(attachmentString)
        learnMoreButton.setAttributedTitle(learnMoreText, for: .normal)
    }

    // MARK: Actions

    @objc private func closeButtonPressed(sender: UIButton) {
        dismiss(animated: true, completion: nil)
        viewModel.trackCloseButtonTapped()
        viewModel.onDismiss?()
    }


    @IBAction func switchButtonPressed(_ sender: Any) {
        // Try to export WordPress data to a shared location before redirecting the user.
        ContentMigrationCoordinator.shared.startAndDo { [weak self] _ in
            JetpackRedirector.redirectToJetpack()
            self?.viewModel.trackSwitchButtonTapped()
        }
    }

    @IBAction func continueButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        viewModel.trackContinueButtonTapped()
        viewModel.onDismiss?()
    }

    @IBAction func learnMoreButtonPressed(_ sender: Any) {
        guard let url = URL(string: Constants.learnMoreURLString) else {
            return
        }

        let source = "jetpack_overlay_\(viewModel.analyticsSource)"
        let webViewController = WebViewControllerFactory.controller(url: url, source: source)
        let navController = UINavigationController(rootViewController: webViewController)
        present(navController, animated: true)
        viewModel.trackLearnMoreTapped()
    }
}

// MARK: Constants

private extension JetpackFullscreenOverlayViewController {
    enum Strings {
        static let learnMoreButtonText = NSLocalizedString("jetpack.fullscreen.overlay.learnMore",
                                                           value: "Learn more at jetpack.com",
                                                           comment: "Title of a button that displays a blog post in a web view.")
    }

    enum Metrics {
        static let closeButtonRadius: CGFloat = 30
        static let mainButtonsContentInsets = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)
        static let mainButtonsContentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        static let learnMoreButtonContentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 24)
        static let learnMoreButtonContentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 24)
        static let externalIconSize = CGSize(width: 16, height: 16)
        static let externalIconBounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        static let switchButtonCornerRadius: CGFloat = 6
        static let titleLineHeightMultiple: CGFloat = 0.88
        static let titleKern: CGFloat = 0.37
        static let buttonsNormalBottomSpacing: CGFloat = 30
        static let singleButtonBottomSpacing: CGFloat = 60
    }

    enum Constants {
        // TODO: Update link
        static let learnMoreURLString = "https://jetpack.com/blog/"
        static let closeButtonSystemName = "xmark.circle.fill"
    }

    enum Colors {
        private static let jetpackGreen50 = UIColor.muriel(color: .jetpackGreen, .shade50).lightVariant()
        private static let jetpackGreen30 = UIColor.muriel(color: .jetpackGreen, .shade30).lightVariant()

        static let backgroundColor = UIColor(light: .systemBackground,
                                             dark: .muriel(color: .jetpackGreen, .shade100))
        static let footnoteTextColor = UIColor(light: .muriel(color: .gray, .shade50),
                                               dark: .muriel(color: .gray, .shade5))
        static let learnMoreButtonTextColor = UIColor(light: jetpackGreen50, dark: jetpackGreen30)
        static let switchButtonBackgroundColor = jetpackGreen50
        static let continueButtonTextColor = UIColor(light: jetpackGreen50, dark: .white)
        static let switchButtonTextColor = UIColor.white
        static let closeButtonTintColor = UIColor(light: .muriel(color: .gray, .shade5),
                                                  dark: .muriel(color: .jetpackGreen, .shade90))
    }
}

fileprivate extension UIColor {
    func lightVariant() -> UIColor {
        return self.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }
}
