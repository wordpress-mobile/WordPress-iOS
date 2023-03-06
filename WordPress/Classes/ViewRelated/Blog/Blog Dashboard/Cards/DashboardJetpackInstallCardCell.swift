import UIKit

class DashboardJetpackInstallCardCell: DashboardCollectionViewCell {

    // MARK: Properties

    private var blog: Blog?
    private weak var presenterViewController: BlogDashboardViewController?

    private lazy var cardViewModel: JetpackRemoteInstallCardViewModel = {
        let onHideThisTap: UIActionHandler = { [weak self] _ in
            guard let self,
                  let helper = JetpackInstallPluginHelper(self.blog) else {
                return
            }
            WPAnalytics.track(.jetpackInstallFullPluginCardDismissed, properties: [WPAppAnalyticsKeyTabSource: "dashboard"])
            helper.hideCard()
            self.presenterViewController?.reloadCardsLocally()
        }

        let onLearnMoreTap: () -> Void = {
            guard let presenterViewController = self.presenterViewController else {
                return
            }
            WPAnalytics.track(.jetpackInstallFullPluginCardTapped, properties: [WPAppAnalyticsKeyTabSource: "dashboard"])
            JetpackInstallPluginHelper.presentOverlayIfNeeded(in: presenterViewController,
                                                              blog: self.blog,
                                                              delegate: presenterViewController,
                                                              force: true)

        }
        return JetpackRemoteInstallCardViewModel(onHideThisTap: onHideThisTap,
                                                 onLearnMoreTap: onLearnMoreTap)
    }()

    private lazy var cardView: JetpackRemoteInstallCardView = {
        let cardView = JetpackRemoteInstallCardView(cardViewModel)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        return cardView
    }()

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Functions

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presenterViewController = viewController
        cardView.updatePlugin(JetpackPlugin(from: blog.jetpackConnectionActivePlugins))
    }

    private func setupView() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: .defaultHigh)
    }

}
