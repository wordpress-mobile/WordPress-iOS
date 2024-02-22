import UIKit
import Lottie
import WordPressUI

final class MovedToJetpackViewController: UIViewController {

    // MARK: - Subviews

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false

        /// Configure constraints
        scrollView.addSubview(containerView)
        scrollView.pinSubviewToAllEdges(containerView)

        return scrollView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        /// Configure constraints
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: Metrics.stackViewMargin),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: Metrics.stackViewMargin),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        return view
    }()

    private lazy var stackView: UIStackView = {
        let subviews = [
            animationContainerView,
            titleLabel,
            descriptionLabel,
            hintLabel,
            jetpackButton,
            learnMoreButton
        ]
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading

        /// Configure spacing
        stackView.spacing = Metrics.stackViewSpacing
        stackView.setCustomSpacing(Metrics.hintToJetpackButtonSpacing, after: hintLabel)

        return stackView
    }()

    private lazy var animationContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        /// Configure constraints
        view.addSubview(animationView)
        view.pinSubviewToAllEdges(animationView)

        return view
    }()

    private lazy var animationView: LottieAnimationView = {
        let animationView = LottieAnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.animation = animation
        return animationView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.title.replacingLastSpaceWithNonBreakingSpace
        label.font = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.textColor = .text
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.description
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.textColor = .text
        return label
    }()

    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.hint
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.textColor = .textSubtle
        return label
    }()

    private lazy var jetpackButton: UIButton = {
        let button = FancyButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(viewModel.jetpackButtonTitle, for: .normal)
        button.isPrimary = true
        button.primaryNormalBackgroundColor = .jetpackGreen
        button.primaryHighlightBackgroundColor = .muriel(color: .jetpackGreen, .shade80)
        button.addTarget(self, action: #selector(jetpackButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(learnMoreAttributedString(), for: .normal)
        button.tintColor = .jetpackGreen
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .regular)
        button.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    private let source: MovedToJetpackSource
    private let viewModel: MovedToJetpackViewModel
    private let tracker: MovedToJetpackEventsTracker

    /// Sets the animation based on the language orientation
    private var animation: LottieAnimation? {
        traitCollection.layoutDirection == .leftToRight ?
        LottieAnimation.named(viewModel.animationLtr) :
        LottieAnimation.named(viewModel.animationRtl)
    }

    // MARK: - Initializers

    @objc init(source: MovedToJetpackSource) {
        self.source = source
        self.viewModel = MovedToJetpackViewModel(source: source)
        self.tracker = MovedToJetpackEventsTracker(source: source)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // This VC is designed to be initialized programmatically.
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        setupView()
        animationView.play()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tracker.trackScreenDisplayed()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        animationView.currentProgress = 1.0
    }

    // MARK: - Navigation overrides

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - View setup

    private func setupView() {
        view.backgroundColor = .basicBackground
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)

        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            containerView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, constant: 0),
            jetpackButton.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
            jetpackButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            jetpackButton.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            learnMoreButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            learnMoreButton.centerXAnchor.constraint(equalTo: stackView.centerXAnchor)
        ])
    }

    private func learnMoreAttributedString() -> NSAttributedString {
        let externalAttachment = NSTextAttachment(image: UIImage.gridicon(.external, size: Metrics.externalIconSize).withTintColor(.jetpackGreen))
        externalAttachment.bounds = Metrics.externalIconBounds
        let attachmentString = NSAttributedString(attachment: externalAttachment)
        let learnMoreText = NSMutableAttributedString(string: "\(viewModel.learnMoreButtonTitle) \u{FEFF}")
        learnMoreText.append(attachmentString)
        return NSAttributedString(attributedString: learnMoreText)
    }

    // MARK: - Button action

    @objc private func jetpackButtonTapped() {
        // Try to export WordPress data to a shared location before redirecting the user.
        ContentMigrationCoordinator.shared.startAndDo { [weak self] _ in
            JetpackRedirector.redirectToJetpack()
            self?.tracker.trackJetpackButtonTapped()
        }
    }

    @objc private func learnMoreButtonTapped() {
        guard let url = URL(string: Constants.learnMoreButtonURL) else {
            return
        }

        let webViewController = WebViewControllerFactory.controller(url: url, source: Constants.learnMoreWebViewSource)
        let navigationController = UINavigationController(rootViewController: webViewController)
        self.present(navigationController, animated: true)

        tracker.trackJetpackLinkTapped()
    }
}

// MARK: - UINavigationControllerDelegate

extension MovedToJetpackViewController: UINavigationControllerDelegate {

    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return supportedInterfaceOrientations
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        return .portrait
    }
}

extension MovedToJetpackViewController {

    private enum Constants {
        static let learnMoreButtonURL = "https://jetpack.com/support/switch-to-the-jetpack-app/"
        static let learnMoreWebViewSource = "jp_removal_static_poster"
    }

    private enum Metrics {
        static let stackViewMargin: CGFloat = 20
        static let stackViewSpacing: CGFloat = 20
        static let hintToJetpackButtonSpacing: CGFloat = 40
        static let buttonHeight: CGFloat = 50
        static let externalIconSize = CGSize(width: 16, height: 16)
        static let externalIconBounds = CGRect(x: 0, y: -2, width: 16, height: 16)
    }
}
