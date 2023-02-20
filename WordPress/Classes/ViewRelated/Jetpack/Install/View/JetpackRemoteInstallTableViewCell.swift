import UIKit

@objcMembers
class JetpackRemoteInstallTableViewCell: UITableViewCell {

    // MARK: Properties

    private var blog: Blog?
    private weak var presenterViewController: BlogDetailsViewController?

    private lazy var cardViewModel: JetpackRemoteInstallCardViewModel = {
        let onHideThisTap: UIActionHandler = { [weak self] _ in
            guard let self,
                  let helper = JetpackInstallPluginHelper(self.blog) else {
                return
            }
            WPAnalytics.track(.jetpackInstallFullPluginCardDismissed, properties: [WPAppAnalyticsKeyTabSource: "site_menu"])
            helper.hideCard()
            self.presenterViewController?.reloadTableView()
        }
        let onLearnMoreTap: () -> Void = {
            guard let presenterViewController = self.presenterViewController else {
                return
            }
            WPAnalytics.track(.jetpackInstallFullPluginCardTapped, properties: [WPAppAnalyticsKeyTabSource: "site_menu"])
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Functions

    func configure(blog: Blog, viewController: BlogDetailsViewController?) {
        self.blog = blog
        self.presenterViewController = viewController
    }

    private func setupView() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: .defaultHigh)
    }

}

// MARK: - BlogDetailsViewController view model

extension BlogDetailsViewController: JetpackRemoteInstallDelegate {

    @objc func jetpackInstallSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}
        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .jetpackInstallCard)
        return section
    }

    func jetpackRemoteInstallCompleted() {
        dismiss(animated: true) {
            self.configureTableViewData()
            self.reloadTableViewPreservingSelection()
        }
    }

    func jetpackRemoteInstallCanceled() {
        dismiss(animated: true) {
            self.configureTableViewData()
            self.reloadTableViewPreservingSelection()
        }
    }

    func jetpackRemoteInstallWebviewFallback() {
        // No op
    }

}
