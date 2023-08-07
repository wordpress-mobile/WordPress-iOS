import SwiftUI
import AutomatticTracks

class DashboardJetpackSocialCardCell: DashboardCollectionViewCell {

    // MARK: - Properties

    private let repository: UserPersistentRepository

    private var blog: Blog?
    private weak var dashboardViewController: BlogDashboardViewController?

    private(set) var displayState: DisplayState = .none {
        didSet {
            guard oldValue != displayState else {
                return
            }
            updateUI()
        }
    }

    private var isNoConnectionViewHidden: Bool {
        get {
            guard let dotComID = blog?.dotComID?.stringValue,
                  let isNoConnectionHidden = noConnectionHiddenSites[dotComID] else {
                return false
            }
            return isNoConnectionHidden
        }
        set {
            guard let dotComID = blog?.dotComID?.stringValue else {
                return
            }
            var currentHiddenSites = noConnectionHiddenSites
            currentHiddenSites[dotComID] = true
            repository.set(currentHiddenSites, forKey: Constants.hideNoConnectionViewKey)
        }
    }

    private var isNoSharesViewHidden: Bool {
        get {
            guard let dotComID = blog?.dotComID?.stringValue,
                  let isNoSharesHidden = noSharesHiddenSites[dotComID] else {
                return false
            }
            return isNoSharesHidden
        }
        set {
            guard let dotComID = blog?.dotComID?.stringValue else {
                return
            }
            var currentHiddenSites = noSharesHiddenSites
            currentHiddenSites[dotComID] = true
            repository.set(currentHiddenSites, forKey: Constants.hideNoSharesViewKey)
        }
    }

    private var noConnectionHiddenSites: [String: Bool] {
        let dictionary = repository.dictionary(forKey: Constants.hideNoConnectionViewKey) as? [String: Bool]
        return dictionary ?? [:]
    }

    private var noSharesHiddenSites: [String: Bool] {
        let dictionary = repository.dictionary(forKey: Constants.hideNoSharesViewKey) as? [String: Bool]
        return dictionary ?? [:]
    }

    // MARK: - UI Properties

    private var cardTitle: String {
        switch displayState {
        case .noConnections:
            return Constants.connectTitle
        case .noShares:
            return Constants.noSharesTitle
        default:
            return ""
        }
    }

    private var cardFrameView: BlogDashboardCardFrameView {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(cardTitle)
        frameView.onEllipsisButtonTap = { }
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu

        return frameView
    }

    private var contextMenu: UIMenu {
        let hideThisAction = UIAction(title: Constants.hideThis,
                                      image: Constants.hideThisImage,
                                      attributes: [UIMenuElement.Attributes.destructive],
                                      handler: contextMenuHandler)
        return UIMenu(title: String(), options: .displayInline, children: [hideThisAction])
    }

    var contextMenuHandler: UIActionHandler {
        return { [weak self] _ in
            guard let self else {
                return
            }
            self.hideCard(for: self.displayState)
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        self.repository = UserPersistentStoreFactory.instance()
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: .jetpackSocialUpdated, object: nil)
    }

    init(repository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.repository = repository
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: .jetpackSocialUpdated, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - DashboardCollectionViewCell

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.dashboardViewController = viewController
        updateDisplayState(for: blog)
    }

    // MARK: - Functions

    static func shouldShowCard(for blog: Blog) -> Bool {
        guard RemoteFeatureFlag.jetpackSocialImprovements.enabled() else {
            return false
        }
        return showNoConnectionView(for: blog) || showNoSharesView(for: blog)
    }

    // MARK: - Constants

    struct Constants {
        static let hideNoConnectionViewKey = "dashboard-social-no-connection-view-hidden"
        static let hideNoSharesViewKey = "dashboard-social-no-shares-view-hidden"
        static let connectTitle = NSLocalizedString("dashboard.card.social.noconnections.title",
                                                    value: "Share across your social networks",
                                                    comment: "Title for the Jetpack Social dashboard card when the user has no social connections.")
        static let noSharesTitle = NSLocalizedString("dashboard.card.social.noshares.title",
                                                    value: "You’re out of shares!",
                                                    comment: "Title for the Jetpack Social dashboard card when the user has no social shares left.")
        static let hideThis = NSLocalizedString("dashboard.card.social.menu.hide",
                                                value: "Hide this",
                                                comment: "Title for a menu action in the context menu on the Jetpack Social dashboard card.")
        static let hideThisImage = UIImage(systemName: "minus.circle")
        static let cardInsets = EdgeInsets(top: 8.0, leading: 16.0, bottom: 8.0, trailing: 16.0)
        static let trackingSource = "home_dashboard"
    }

    enum DisplayState {
        case none
        case noConnections
        case noShares
    }

}

// MARK: - Private Functions

private extension DashboardJetpackSocialCardCell {

    static func showNoConnectionView(for blog: Blog) -> Bool {
        guard let context = blog.managedObjectContext,
              let dotComID = blog.dotComID?.stringValue,
              let services = try? PublicizeService.allSupportedServices(in: context),
              let connections = blog.connections else {
            return false
        }
        let repository = UserPersistentStoreFactory.instance()
        let hideNoConnectionViewKey = DashboardJetpackSocialCardCell.Constants.hideNoConnectionViewKey
        let hiddenSites = (repository.dictionary(forKey: hideNoConnectionViewKey) as? [String: Bool]) ?? [:]
        let isNoConnectionViewHidden = hiddenSites[dotComID] ?? false

        return blog.supportsPublicize()
        && services.count > 0
        && connections.count == 0
        && !isNoConnectionViewHidden
    }

    func updateDisplayState(for blog: Blog) {
        if DashboardJetpackSocialCardCell.showNoConnectionView(for: blog) {
            displayState = .noConnections
        } else if DashboardJetpackSocialCardCell.showNoSharesView(for: blog) {
            displayState = .noShares
        } else {
            displayState = .none
        }
    }

    func updateUI() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
            return
        }

        var card: UIView?
        switch displayState {
        case .noConnections:
            card = createNoConnectionCard()
        case .noShares:
            card = createNoSharesCard()
        default:
            card = nil
        }
        if let card {
            for subview in contentView.subviews {
                subview.removeFromSuperview()
            }
            contentView.addSubview(card)
            contentView.pinSubviewToAllEdges(card)
            contentView.layoutIfNeeded()
        } else {
            dashboardViewController?.reloadCardsLocally()
        }
    }

    func createNoConnectionCard() -> UIView? {
        guard let context = blog?.managedObjectContext,
              let services = try? PublicizeService.allSupportedServices(in: context) else {
            // Note: The context and publicize services are checked prior to this call in
            // `showNoConnectionView`. This scenario *shouldn't* be possible.
            assertionFailure("No managed object context or publicize services")
            let error = JetpackSocialError.noConnectionViewInvalidState
            CrashLogging.main.logError(error, userInfo: ["source": Constants.trackingSource])
            return nil
        }
        WPAnalytics.track(.jetpackSocialNoConnectionCardDisplayed,
                          properties: ["source": Constants.trackingSource])
        let card = cardFrameView
        let viewModel = JetpackSocialNoConnectionViewModel(services: services,
                                                           padding: Constants.cardInsets,
                                                           hideNotNow: true,
                                                           bodyTextColor: .secondaryLabel,
                                                           onConnectTap: onConnectTap())
        let noConnectionViewController = JetpackSocialNoConnectionView.createHostController(with: viewModel)
        card.add(subview: noConnectionViewController.view)
        return card
    }

    func onConnectTap() -> () -> Void {
        return { [weak self] in
            WPAnalytics.track(.jetpackSocialNoConnectionCTATapped,
                              properties: ["source": Constants.trackingSource])
            guard let self,
                  let blog = self.blog,
                  let controller = SharingViewController(blog: blog, delegate: self) else {
                return
            }
            self.dashboardViewController?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    static func showNoSharesView(for blog: Blog) -> Bool {
        guard let sharingLimit = blog.sharingLimit,
              let dotComID = blog.dotComID?.stringValue,
              let connections = blog.connections as? Set<PublicizeConnection> else {
            return false
        }
        let repository = UserPersistentStoreFactory.instance()
        let hideNoSharesViewKey = DashboardJetpackSocialCardCell.Constants.hideNoSharesViewKey
        let hiddenSites = (repository.dictionary(forKey: hideNoSharesViewKey) as? [String: Bool]) ?? [:]
        let isNoSharesViewHidden = hiddenSites[dotComID] ?? false

        return blog.supportsPublicize()
        && connections.filter { !$0.requiresUserAction() }.count > 0
        && !isNoSharesViewHidden
        && sharingLimit.remaining == 0
    }

    func createNoSharesCard() -> UIView? {
        guard let connections = blog?.connections as? Set<PublicizeConnection> else {
            assertionFailure("No social connections")
            let error = JetpackSocialError.noSharesViewInvalidState
            CrashLogging.main.logError(error, userInfo: ["source": "social_dashboard_card"])
            return nil
        }
        WPAnalytics.track(.jetpackSocialShareLimitDisplayed,
                          properties: ["source": Constants.trackingSource])
        let card = cardFrameView
        let filteredConnections = connections.filter { !$0.requiresUserAction() }
        let services = filteredConnections.reduce(into: [PublicizeService.ServiceName]()) { partialResult, connection in
            guard let service = PublicizeService.ServiceName(rawValue: connection.service) else {
                return
            }
            if !partialResult.contains(service) {
                partialResult.append(service)
            }
        }
        let viewModel = JetpackSocialNoSharesViewModel(services: services,
                                                       totalServiceCount: filteredConnections.count,
                                                       onSubscribeTap: onSubscribeTap())
        let noSharesView = UIView.embedSwiftUIView(JetpackSocialNoSharesView(viewModel: viewModel))
        card.add(subview: noSharesView)
        return card
    }

    func onSubscribeTap() -> () -> Void {
        return { [weak self] in
        WPAnalytics.track(.jetpackSocialUpgradeLinkTapped,
                          properties: ["source": Constants.trackingSource])
            guard let blog = self?.blog,
                  let hostname = blog.hostname,
                  let url = URL(string: "https://wordpress.com/checkout/\(hostname)/jetpack_social_basic_yearly") else {
                return
            }
            let webViewController = WebViewControllerFactory.controller(url: url,
                                                                        blog: blog,
                                                                        source: "dashboard_card_no_shares_subscribe_now") {
                self?.checkoutDismissed()
            }
            let navigationController = UINavigationController(rootViewController: webViewController)
            self?.dashboardViewController?.present(navigationController, animated: true)
        }
    }

    func checkoutDismissed() {
        guard let blog else {
            return
        }
        let coreDataStack = ContextManager.shared
        let service = BlogService(coreDataStack: coreDataStack)
        service.syncBlog(blog) { [weak self] in
            let sharingLimit: PublicizeInfo.SharingLimit? = coreDataStack.performQuery { context in
                guard let dotComID = blog.dotComID,
                      let blog = Blog.lookup(withID: dotComID, in: context) else {
                    return nil
                }
                return blog.sharingLimit
            }
            if sharingLimit == nil || sharingLimit?.remaining ?? 0 > 0 {
                self?.dashboardViewController?.reloadCardsLocally()
            }
        } failure: { error in
            DDLogError("Failed to sync blog after dismissing checkout webview due to error: \(error)")
        }
    }

    @objc func handleNotification() {
        guard let blog else {
            return
        }
        updateDisplayState(for: blog)
    }

    func hideCard(for state: DisplayState) {
        switch state {
        case .noConnections:
            isNoConnectionViewHidden = true
            WPAnalytics.track(.jetpackSocialNoConnectionCardDismissed,
                              properties: ["source": Constants.trackingSource])
        case .noShares:
            isNoSharesViewHidden = true
            WPAnalytics.track(.jetpackSocialShareLimitDismissed,
                              properties: ["source": Constants.trackingSource])
        default:
            break
        }
        dashboardViewController?.reloadCardsLocally()
    }

}

// MARK: - SharingViewControllerDelegate

extension DashboardJetpackSocialCardCell: SharingViewControllerDelegate {

    func didChangePublicizeServices() {
        dashboardViewController?.reloadCardsLocally()
    }

}

// MARK: - Notification

extension NSNotification.Name {

    static let jetpackSocialUpdated = NSNotification.Name(rawValue: "JetpackSocialUpdated")

}
