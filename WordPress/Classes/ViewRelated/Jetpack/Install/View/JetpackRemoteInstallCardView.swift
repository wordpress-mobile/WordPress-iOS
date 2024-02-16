import UIKit
import Lottie

class JetpackRemoteInstallCardView: UIView {

    // MARK: Properties

    private var viewModel: JetpackRemoteInstallCardViewModel

    private lazy var animation: LottieAnimation? = {
        effectiveUserInterfaceLayoutDirection == .leftToRight ?
        LottieAnimation.named(Constants.lottieLTRFileName) :
        LottieAnimation.named(Constants.lottieRTLFileName)
    }()

    private lazy var logosAnimationView: LottieAnimationView = {
        let view = LottieAnimationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.animation = animation
        let animationSize = animation?.size ?? .init(width: 1, height: 1)
        let ratio = animationSize.width / animationSize.height
        view.addConstraints([
            view.heightAnchor.constraint(equalToConstant: Constants.iconHeight),
            view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: ratio),
        ])
        view.currentProgress = 1.0

        return view
    }()

    private lazy var logosStackView: UIStackView = {
        return UIStackView(arrangedSubviews: [logosAnimationView, UIView()])
    }()

    private lazy var noticeLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.noticeLabelFont
        label.attributedText = viewModel.noticeLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var learnMoreButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.learnMore, for: .normal)
        button.setTitleColor(.primary, for: .normal)
        button.titleLabel?.font = Constants.learnMoreFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onLearnMoreTap), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [logosStackView, noticeLabel, learnMoreButton])
        stackView.axis = .vertical
        stackView.spacing = Constants.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Constants.contentDirectionalLayoutMargins
        return stackView
    }()

    private lazy var contextMenu: UIMenu = {
        let hideThisAction = UIAction(title: Strings.hideThis,
                                      image: Constants.hideThisImage,
                                      attributes: [UIMenuElement.Attributes.destructive],
                                      handler: viewModel.onHideThisTap)
        return UIMenu(title: String(), options: .displayInline, children: [hideThisAction])
    }()

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.onEllipsisButtonTap = {}
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu
        frameView.add(subview: contentStackView)
        return frameView
    }()

    // MARK: Initializers

    init(_ viewModel: JetpackRemoteInstallCardViewModel = JetpackRemoteInstallCardViewModel()) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Functions

    func updatePlugin(_ plugin: JetpackPlugin?) {
        guard let plugin else {
            return
        }
        viewModel.installedPlugin = plugin
        noticeLabel.attributedText = viewModel.noticeLabel
    }

    @objc func onLearnMoreTap() {
        viewModel.onLearnMoreTap()
    }

    private func setupView() {
        addSubview(cardFrameView)
        pinSubviewToAllEdges(cardFrameView)
    }

    // MARK: Constants

    struct Constants {
        static let lottieLTRFileName = "JetpackInstallPluginLogoAnimation_ltr"
        static let lottieRTLFileName = "JetpackInstallPluginLogoAnimation_rtl"
        static let hideThisImage = UIImage(systemName: "eye.slash")
        static let iconHeight: CGFloat = 30.0
        static let contentSpacing: CGFloat = 10.0
        static let noticeLabelFont = WPStyleGuide.fontForTextStyle(.callout)
        static let learnMoreFont = WPStyleGuide.fontForTextStyle(.callout).semibold()
        static let contentDirectionalLayoutMargins = NSDirectionalEdgeInsets(top: -24.0, leading: 20.0, bottom: 12.0, trailing: 20.0)
    }

    struct Strings {
        static let learnMore = NSLocalizedString("jetpackinstallcard.button.learn",
                                                 value: "Learn more",
                                                 comment: "Title for a call-to-action button on the Jetpack install card.")
        static let hideThis = NSLocalizedString("jetpackinstallcard.menu.hide",
                                                 value: "Hide this",
                                                 comment: "Title for a menu action in the context menu on the Jetpack install card.")

    }

}

// MARK: - JetpackRemoteInstallCardViewModel

struct JetpackRemoteInstallCardViewModel {

    let onHideThisTap: UIActionHandler
    let onLearnMoreTap: () -> Void
    var installedPlugin: JetpackPlugin

    var noticeLabel: NSAttributedString {
        switch installedPlugin {
        case .multiple:
            return NSAttributedString(string: Strings.multiplePlugins)
        default:
            let noticeText = String(format: Strings.individualPluginFormat, installedPlugin.displayName)
            let boldNoticeText = NSMutableAttributedString(string: noticeText)
            guard let range = noticeText.nsRange(of: installedPlugin.displayName) else {
                return boldNoticeText
            }
            boldNoticeText.addAttributes([.font: WPStyleGuide.fontForTextStyle(.callout, fontWeight: .bold)], range: range)
            return boldNoticeText
        }
    }

    init(onHideThisTap: @escaping UIActionHandler = { _ in },
         onLearnMoreTap: @escaping () -> Void = {},
         installedPlugin: JetpackPlugin = .multiple) {
        self.onHideThisTap = onHideThisTap
        self.onLearnMoreTap = onLearnMoreTap
        self.installedPlugin = installedPlugin
    }

    // MARK: Constants

    private struct Strings {
        static let individualPluginFormat = NSLocalizedString("jetpackinstallcard.notice.individual",
                                                              value: "This site is using the %1$@ plugin, which doesn't support all features of the app yet. Please install the full Jetpack plugin.",
                                                              comment: "Text displayed in the Jetpack install card on the Home screen and Menu screen when a user has an individual Jetpack plugin installed but not the full plugin. %1$@ is a placeholder for the plugin the user has installed. %1$@ is bold.")
        static let multiplePlugins = NSLocalizedString("jetpackinstallcard.notice.multiple",
                                                       value: "This site is using individual Jetpack plugins, which don’t support all features of the app yet. Please install the full Jetpack plugin.",
                                                       comment: "Text displayed in the Jetpack install card on the Home screen and Menu screen when a user has multiple installed individual Jetpack plugins but not the full plugin.")
    }

}
