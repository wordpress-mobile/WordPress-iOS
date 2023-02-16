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
    @IBOutlet weak var learnMoreSuperView: UIView!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var buttonsSuperViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionInfoLabel: UILabel!

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
        addSecondaryViewIfAvailable()
        configureNavigationBar()
        applyStyles()
        setupConstraints()
        setupContent()
        setupColors()
        setupFonts()
        setupButtons()
        animationView.play()
        viewModel.trackOverlayDisplayed()
    }

    // MARK: Helpers

    private func addSecondaryViewIfAvailable() {
        guard let secondaryView = viewModel.secondaryView,
              let index = contentStackView.arrangedSubviews.firstIndex(of: learnMoreSuperView) else {
            return
        }
        contentStackView.insertArrangedSubview(secondaryView, at: index)
    }

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
        contentStackView.spacing = viewModel.isCompact ? Metrics.compactStackViewSpacing : Metrics.normalStackViewSpacing
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
        subtitleLabel.attributedText = viewModel.subtitle
        footnoteLabel.text = viewModel.footnote
        actionInfoLabel.attributedText = viewModel.actionInfoText
        switchButton.setTitle(viewModel.switchButtonText, for: .normal)
        continueButton.setTitle(viewModel.continueButtonText, for: .normal)
        footnoteLabel.isHidden = viewModel.footnoteIsHidden
        learnMoreButton.isHidden = viewModel.learnMoreButtonIsHidden
        continueButton.isHidden = viewModel.continueButtonIsHidden
        setupLearnMoreButtonTitle()
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
        actionInfoLabel.textColor = Colors.actionInfoTextColor
        learnMoreButton.tintColor = Colors.learnMoreButtonTextColor
        switchButton.backgroundColor = Colors.switchButtonBackgroundColor
        switchButton.tintColor = Colors.switchButtonTextColor
        continueButton.tintColor = Colors.continueButtonTextColor
    }

    private func setupFonts() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.adjustsFontForContentSizeCategory = true
        footnoteLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        footnoteLabel.adjustsFontForContentSizeCategory = true
        actionInfoLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        actionInfoLabel.adjustsFontForContentSizeCategory = true
        learnMoreButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        switchButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        continueButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
    }

    private func setupButtons() {
        setupButtonInsets()
        switchButton.titleLabel?.textAlignment = .center
        continueButton.titleLabel?.textAlignment = .center
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

    private func setupLearnMoreButtonTitle() {
        let externalAttachment = NSTextAttachment(image: UIImage.gridicon(.external, size: Metrics.externalIconSize).withTintColor(Colors.learnMoreButtonTextColor))
        externalAttachment.bounds = Metrics.externalIconBounds
        let attachmentString = NSAttributedString(attachment: externalAttachment)

        let learnMoreText = NSMutableAttributedString(string: "\(Strings.learnMoreButtonText) \u{FEFF}")
        learnMoreText.append(attachmentString)
        learnMoreButton.setAttributedTitle(learnMoreText, for: .normal)
    }

    // MARK: Actions

    @objc private func closeButtonPressed(sender: UIButton) {
        viewModel.trackCloseButtonTapped()
        viewModel.onWillDismiss?()
        dismiss(animated: true) { [weak self] in
            self?.viewModel.onDidDismiss?()
        }
    }


    @IBAction func switchButtonPressed(_ sender: Any) {
        // Try to export WordPress data to a shared location before redirecting the user.
        ContentMigrationCoordinator.shared.startAndDo { [weak self] _ in
            JetpackRedirector.redirectToJetpack()
            self?.viewModel.trackSwitchButtonTapped()
        }
    }

    @IBAction func continueButtonPressed(_ sender: Any) {
        viewModel.trackContinueButtonTapped()
        viewModel.onWillDismiss?()
        dismiss(animated: true) { [weak self] in
            self?.viewModel.onDidDismiss?()
        }
    }

    @IBAction func learnMoreButtonPressed(_ sender: Any) {
        guard let urlString = viewModel.learnMoreButtonURL,
              let url = URL(string: urlString) else {
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
        static let normalStackViewSpacing: CGFloat = 20
        static let compactStackViewSpacing: CGFloat = 10
        static let closeButtonRadius: CGFloat = 30
        static let mainButtonsContentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        static let mainButtonsContentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
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
        static let closeButtonSystemName = "xmark.circle.fill"
    }

    enum Colors {
        private static let jetpackGreen50 = UIColor.muriel(color: .jetpackGreen, .shade50).lightVariant()
        private static let jetpackGreen30 = UIColor.muriel(color: .jetpackGreen, .shade30).lightVariant()
        private static let jetpackGreen90 = UIColor.muriel(color: .jetpackGreen, .shade90).lightVariant()

        static let backgroundColor = UIColor(light: .systemBackground,
                                             dark: .muriel(color: .jetpackGreen, .shade100))
        static let footnoteTextColor = UIColor(light: .muriel(color: .gray, .shade50),
                                               dark: .muriel(color: .gray, .shade5))
        static let actionInfoTextColor = UIColor.textSubtle
        static let learnMoreButtonTextColor = UIColor(light: jetpackGreen50, dark: jetpackGreen30)
        static let switchButtonBackgroundColor = jetpackGreen50
        static let continueButtonTextColor = UIColor(light: jetpackGreen50, dark: .white)
        static let switchButtonTextColor = UIColor.white
        static let closeButtonTintColor = UIColor(light: .muriel(color: .gray, .shade5),
                                                  dark: jetpackGreen90)
    }
}
