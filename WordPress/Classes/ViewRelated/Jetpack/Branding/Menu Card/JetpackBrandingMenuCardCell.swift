import UIKit
import Lottie

class JetpackBrandingMenuCardCell: UITableViewCell {

    // MARK: Private Variables

    private weak var viewController: BlogDetailsViewController?
    private var presenter: JetpackBrandingMenuCardPresenter?
    private var config: JetpackBrandingMenuCardPresenter.Config?

    /// Sets the animation based on the language orientation
    private var animation: LottieAnimation? {
        traitCollection.layoutDirection == .leftToRight ?
        LottieAnimation.named(Constants.animationLtr) :
        LottieAnimation.named(Constants.animationRtl)
    }

    private var cardType: JetpackBrandingMenuCardPresenter.Config.CardType {
        config?.type ?? .expanded
    }

    // MARK: Lazy Loading General Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.hideHeader()
        return frameView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    // MARK: Lazy Loading Expanded Card Views

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

    private lazy var logosAnimationView: LottieAnimationView = {
        let view = LottieAnimationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.animation = animation

        // Height Constraint
        view.heightAnchor.constraint(equalToConstant: Metrics.Expanded.animationsViewHeight).isActive = true

        // Width constraint to achieve aspect ratio
        let animationSize = animation?.size ?? .init(width: 1, height: 1)
        let ratio = animationSize.width / animationSize.height
        view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: ratio).isActive = true

        return view
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
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

        var learnMoreButtonConfig: UIButton.Configuration = .plain()
        learnMoreButtonConfig.contentInsets = Metrics.learnMoreButtonContentInsets
        button.configuration = learnMoreButtonConfig

        return button
    }()

    // MARK: Lazy Loading Compact Card Views

    private lazy var jetpackIconImageView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(named: Constants.jetpackIcon)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.heightAnchor.constraint(equalToConstant: Metrics.Compact.logoImageViewSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: Metrics.Compact.logoImageViewSize).isActive = true
        return imageView
    }()

    private lazy var ellipsisButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.gridicon(.ellipsis).imageWithTintColor(Metrics.Compact.ellipsisButtonColor), for: .normal)
        button.contentEdgeInsets = Metrics.Compact.ellipsisButtonPadding
        button.isAccessibilityElement = true
        button.accessibilityLabel = Strings.ellipsisButtonAccessibilityLabel
        button.accessibilityTraits = .button
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.showsMenuAsPrimaryAction = true
        button.menu = contextMenu
        button.on([.touchUpInside, .menuActionTriggered]) { [weak self] _ in
            self?.presenter?.trackContextualMenuAccessed()
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
        addSubviews()
    }

    // MARK: Cell Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()

        containerStackView.removeAllSubviews()
    }

    // MARK: Helpers

    private func configure() {
        setupContent()
        applyStyles()
        configureCardFrame()

        presenter?.trackCardShown()
    }

    private func addSubviews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Metrics.cardFrameConstraintPriority)
        cardFrameView.add(subview: containerStackView)
    }

    private func setupContent() {
        containerStackView.addArrangedSubviews(stackViewSubviews)
        logosAnimationView.currentProgress = 1.0
        label.text = config?.description
    }

    private func applyStyles() {
        containerStackView.axis = stackViewAxis
        containerStackView.spacing = stackViewSpacing
        containerStackView.directionalLayoutMargins = stackViewLayoutMargins
        label.font = labelFont
        label.textColor = labelTextColor
        label.numberOfLines = labelNumberOfLines
    }

    private func configureCardFrame() {
        if cardType == .expanded {
            cardFrameView.configureButtonContainerStackView()
            cardFrameView.onEllipsisButtonTap = { [weak self] in
                self?.presenter?.trackContextualMenuAccessed()
            }
            cardFrameView.ellipsisButton.showsMenuAsPrimaryAction = true
            cardFrameView.ellipsisButton.menu = contextMenu
        }
        else {
            cardFrameView.removeButtonContainerStackView()
            cardFrameView.onEllipsisButtonTap = nil
        }
    }

    // MARK: Actions

    @objc private func learnMoreButtonTapped() {
        guard let viewController else {
            return
        }

        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: viewController,
                                                                 source: .card,
                                                                 blog: viewController.blog)
        presenter?.trackLinkTapped()
    }
}

// MARK: Contextual Menu

private extension JetpackBrandingMenuCardCell {

    // MARK: Items

    // Defines the structure of the contextual menu items.
    private var contextMenuItems: [MenuItem] {
        return [.remindLater(remindMeLaterTapped), .hide(hideThisTapped)]
    }

    // MARK: Menu Creation

    private var contextMenu: UIMenu {
        let actions = contextMenuItems.map { $0.toAction }
        return .init(title: String(), options: .displayInline, children: actions)
    }

    // MARK: Actions

    private func remindMeLaterTapped() {
        presenter?.remindLaterTapped()
        viewController?.reloadTableView()
    }

    private func hideThisTapped() {
        presenter?.hideThisTapped()
        viewController?.reloadTableView()
    }
}

private extension JetpackBrandingMenuCardCell {
    var stackViewAxis: NSLayoutConstraint.Axis {
        switch cardType {
        case .compact:
            return .horizontal
        case .expanded:
            return .vertical
        }
    }

    var stackViewSpacing: CGFloat {
        switch cardType {
        case .compact:
            return Metrics.Compact.spacing
        case .expanded:
            return Metrics.Expanded.spacing
        }
    }

    var stackViewLayoutMargins: NSDirectionalEdgeInsets {
        switch cardType {
        case .compact:
            return Metrics.Compact.containerMargins
        case .expanded:
            return Metrics.Expanded.containerMargins
        }
    }

    var stackViewSubviews: [UIView] {
        switch cardType {
        case .compact:
            return [jetpackIconImageView, label, ellipsisButton]
        case .expanded:
            return [logosSuperview, label, learnMoreSuperview]
        }
    }

    var labelFont: UIFont {
        switch cardType {
        case .compact:
            return Metrics.Compact.labelFont
        case .expanded:
            return Metrics.Expanded.labelFont
        }
    }

    var labelTextColor: UIColor {
        switch cardType {
        case .compact:
            return Metrics.Compact.labelTextColor
        case .expanded:
            return Metrics.Expanded.labelTextColor
        }
    }

    var labelNumberOfLines: Int {
        switch cardType {
        case .compact:
            return 1
        case .expanded:
            return 0
        }
    }

}

private extension JetpackBrandingMenuCardCell {

    enum Metrics {
        // General
        enum Expanded {
            static let spacing: CGFloat = 10
            static let containerMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 12, trailing: 20)
            static let animationsViewHeight: CGFloat = 32
            static var labelFont: UIFont {
                let maximumFontPointSize: CGFloat = 16
                let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                let font = UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maximumFontPointSize))
                return UIFontMetrics.default.scaledFont(for: font)
            }
            static let labelTextColor: UIColor = .label
        }

        enum Compact {
            static let spacing: CGFloat = 15
            static let containerMargins = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 7, trailing: 12)
            static let logoImageViewSize: CGFloat = 24
            static let ellipsisButtonPadding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            static let ellipsisButtonColor = UIColor.muriel(color: .gray, .shade20)
            static var labelFont: UIFont {
                let maximumFontPointSize: CGFloat = 17
                let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                let font = UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maximumFontPointSize))
                return UIFontMetrics.default.scaledFont(for: font)
            }
            static let labelTextColor: UIColor = UIColor.muriel(color: .jetpackGreen, .shade40)
        }

        static let cardFrameConstraintPriority = UILayoutPriority(999)

        // Learn more button
        static let learnMoreButtonContentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 24)
        static let learnMoreButtonTextColor: UIColor = UIColor.muriel(color: .jetpackGreen, .shade40)
    }

    enum Constants {
        static let animationLtr = "JetpackAllFeaturesLogosAnimation_ltr"
        static let animationRtl = "JetpackAllFeaturesLogosAnimation_rtl"
        static let analyticsSource = "jetpack_menu_card"
        static let remindMeLaterSystemImageName = "alarm"
        static let hideThisLaterSystemImageName = "eye.slash"
        static let jetpackIcon = "icon-jetpack"
    }

    enum Strings {
        static let learnMoreButtonText = NSLocalizedString("jetpack.menuCard.learnMore",
                                                           value: "Learn more",
                                                           comment: "Title of a button that displays a blog post in a web view.")
        static let remindMeLaterMenuItemTitle = NSLocalizedString("jetpack.menuCard.remindLater",
                                                                  value: "Remind me later",
                                                                  comment: "Menu item title to hide the card for now and show it later.")
        static let hideCardMenuItemTitle = NSLocalizedString("jetpack.menuCard.hide",
                                                                  value: "Hide this",
                                                                  comment: "Menu item title to hide the card.")
        static let ellipsisButtonAccessibilityLabel = NSLocalizedString("ellipsisButton.AccessibilityLabel",
                                                                        value: "More",
                                                                        comment: "Accessibility label for more button in dashboard quick start card.")
    }

    enum MenuItem {
        case remindLater(_ handler: () -> Void)
        case hide(_ handler: () -> Void)

        var title: String {
            switch self {
            case .remindLater:
                return Strings.remindMeLaterMenuItemTitle
            case .hide:
                return Strings.hideCardMenuItemTitle
            }
        }

        var image: UIImage? {
            switch self {
            case .remindLater:
                return .init(systemName: Constants.remindMeLaterSystemImageName)
            case .hide:
                return .init(systemName: Constants.hideThisLaterSystemImageName)
            }
        }

        var toAction: UIAction {
            switch self {
            case .remindLater(let handler),
                 .hide(let handler):
                return UIAction(title: title, image: image, attributes: []) { _ in
                    handler()
                }
            }
        }
    }
}

extension JetpackBrandingMenuCardCell {

    @objc(configureWithViewController:)
    func configure(with viewController: BlogDetailsViewController) {
        self.viewController = viewController
        presenter = JetpackBrandingMenuCardPresenter(blog: viewController.blog)
        config = presenter?.cardConfig()
        configure()
    }
}
