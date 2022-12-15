import UIKit
import Lottie

class JetpackBrandingMenuCardCell: UITableViewCell {

    // MARK: Private Variables

    private weak var viewController: UIViewController?

    /// Sets the animation based on the language orientation
    private var animation: Animation? {
        traitCollection.layoutDirection == .leftToRight ?
        Animation.named(Constants.animationLtr) :
        Animation.named(Constants.animationRtl)
    }

    // MARK: Lazy Loading Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.configureButtonContainerStackView()
        frameView.hideHeader()

        // NOTE: Remove the logic when support for iOS 14 is dropped
        if #available (iOS 15.0, *) {
            // assign an empty closure so the button appears.
            frameView.onEllipsisButtonTap = {}
            frameView.ellipsisButton.showsMenuAsPrimaryAction = true
//            frameView.ellipsisButton.menu = contextMenu
        } else {
            // Show a fallback implementation using `MenuSheetViewController`.
            // iOS 13 doesn't support showing UIMenu programmatically.
            // iOS 14 doesn't support `UIDeferredMenuElement.uncached`.
            frameView.onEllipsisButtonTap = { [weak self] in
//                self?.showMenuSheet()
            }
        }

        return frameView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.spacing
        stackView.layoutMargins = Metrics.containerMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews([logosSuperview, descriptionLabel, learnMoreSuperview])
        return stackView
    }()

    private lazy var logosSuperview: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(logosAnimationView)

        view.topAnchor.constraint(equalTo: logosAnimationView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: logosAnimationView.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: logosAnimationView.leadingAnchor).isActive = true

        return view
    }()

    private lazy var logosAnimationView: AnimationView = {
        let view = AnimationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.animation = animation

        // Height Constraint
        view.heightAnchor.constraint(equalToConstant: Metrics.animationsViewHeight).isActive = true

        // Width constraint to achieve aspect ratio
        let animationSize = animation?.size ?? .init(width: 1, height: 1)
        let ratio = animationSize.width / animationSize.height
        view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: ratio).isActive = true

        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Metrics.descriptionFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private lazy var learnMoreSuperview: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(learnMoreButton)

        view.topAnchor.constraint(equalTo: learnMoreButton.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: learnMoreButton.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: learnMoreButton.leadingAnchor).isActive = true

        return view
    }()

    private lazy var learnMoreButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Metrics.learnMoreButtonTextColor
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(Strings.learnMoreButtonText, for: .normal)
        button.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            var learnMoreButtonConfig: UIButton.Configuration = .plain()
            learnMoreButtonConfig.contentInsets = Metrics.learnMoreButtonContentInsets
            button.configuration = learnMoreButtonConfig
        } else {
            button.contentEdgeInsets = Metrics.learnMoreButtonContentEdgeInsets
            button.flipInsetsForRightToLeftLayoutDirection()
        }

        return button
    }()

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupViews()
        setupContent()
    }

    // MARK: Helpers

    private func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Metrics.cardFrameConstraintPriority)
        cardFrameView.add(subview: containerStackView)
    }

    private func setupContent() {
        logosAnimationView.play()
        let config = JetpackBrandingMenuCardCoordinator.cardConfig
        descriptionLabel.text = config?.description
        learnMoreSuperview.isHidden = config?.learnMoreButtonURL == nil
    }

    // MARK: Actions

    @objc private func learnMoreButtonTapped() {
        guard let config = JetpackBrandingMenuCardCoordinator.cardConfig,
              let urlString = config.learnMoreButtonURL,
              let url = URL(string: urlString) else {
            return
        }

        let webViewController = WebViewControllerFactory.controller(url: url, source: Constants.analyticsSource)
        let navController = UINavigationController(rootViewController: webViewController)
        viewController?.present(navController, animated: true)
    }
}

private extension JetpackBrandingMenuCardCell {

    enum Metrics {
        // General
        static let spacing: CGFloat = 10
        static let containerMargins = UIEdgeInsets(top: 20, left: 20, bottom: 12, right: 20)
        static let cardFrameConstraintPriority = UILayoutPriority(999)

        // Animation view
        static let animationsViewHeight: CGFloat = 32

        // Description Label
        static var descriptionFont: UIFont {
            let maximumFontPointSize: CGFloat = 16
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            let font = UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maximumFontPointSize))
            return UIFontMetrics.default.scaledFont(for: font)
        }

        // Learn more button
        static let learnMoreButtonContentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 24)
        static let learnMoreButtonContentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 24)
        static let learnMoreButtonTextColor: UIColor = UIColor.muriel(color: .jetpackGreen, .shade40)
    }

    enum Constants {
        static let animationLtr = "JetpackAllFeaturesLogosAnimation_ltr"
        static let animationRtl = "JetpackAllFeaturesLogosAnimation_rtl"
        static let analyticsSource = "jetpack_menu_card"
    }

    enum Strings {
        static let learnMoreButtonText = NSLocalizedString("jetpack.menuCard.learnMore",
                                                           value: "Learn more",
                                                           comment: "Title of a button that displays a blog post in a web view.")
    }
}

// TODO: Consider moving to a different file
extension JetpackBrandingMenuCardCell {

    @objc(configureWithViewController:)
    func configure(with viewController: UIViewController) {
        self.viewController = viewController
    }
}

// TODO: Consider moving to a different file
extension BlogDetailsViewController {

    @objc func jetpackCardSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}

        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .jetpackBrandingCard)
        return section
    }
}
