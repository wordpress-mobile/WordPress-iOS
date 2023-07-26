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

    private var noConnectionHiddenSites: [String: Bool] {
        let dictionary = repository.dictionary(forKey: Constants.hideNoConnectionViewKey) as? [String: Bool]
        return dictionary ?? [:]
    }

    // MARK: - UI Properties

    private var cardTitle: String {
        switch displayState {
        // TODO: Out of shares title
        case .noConnections:
            return Constants.connectTitle
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
        // TODO: Out of shares context menu handler
        let hideNoConnectionView: UIActionHandler = { [weak self] _ in
            guard let self else {
                return
            }

            self.isNoConnectionViewHidden = true
            self.dashboardViewController?.reloadCardsLocally()
        }

        let hideThisAction = UIAction(title: Constants.hideThis,
                                      image: Constants.hideThisImage,
                                      attributes: [UIMenuElement.Attributes.destructive],
                                      handler: hideNoConnectionView)
        return UIMenu(title: String(), options: .displayInline, children: [hideThisAction])
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        self.repository = UserPersistentStoreFactory.instance()
        super.init(frame: frame)
    }

    init(repository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.repository = repository
        super.init(frame: .zero)
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
        guard FeatureFlag.jetpackSocial.enabled else {
            return false
        }
        // TODO: Show when user is out of shares
        return showNoConnectionView(for: blog)
    }

    // MARK: - Constants

    struct Constants {
        static let hideNoConnectionViewKey = "dashboard-social-no-connection-view-hidden"
        static let connectTitle = NSLocalizedString("dashboard.card.social.noconnections.title",
                                                    value: "Share across your social networks",
                                                    comment: "Title for the Jetpack Social dashboard card when the user has no social connections.")
        static let hideThis = NSLocalizedString("dashboard.card.social.menu.hide",
                                                value: "Hide this",
                                                comment: "Title for a menu action in the context menu on the Jetpack Social dashboard card.")
        static let hideThisImage = UIImage(systemName: "minus.circle")
        static let cardInsets = EdgeInsets(top: 8.0, leading: 16.0, bottom: 8.0, trailing: 16.0)
    }

    enum DisplayState {
        case none
        case noConnections
        // TODO: State for when a user is out of shares
    }

}

// MARK: - Private Functions

private extension DashboardJetpackSocialCardCell {

    static func showNoConnectionView(for blog: Blog) -> Bool {
        guard let context = blog.managedObjectContext,
              let dotComID = blog.dotComID?.stringValue,
              let services = try? PublicizeService.allPublicizeServices(in: context),
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
        // TODO: State for when a user is out of shares
        let showNoConnectionView = DashboardJetpackSocialCardCell.showNoConnectionView(for: blog)
        displayState = showNoConnectionView ? .noConnections : .none
    }

    func updateUI() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
            return
        }

        // TODO: Out of shares view
        if let noConnectionCard = createNoConnectionCard() {
            for subview in contentView.subviews {
                subview.removeFromSuperview()
            }
            contentView.addSubview(noConnectionCard)
            contentView.pinSubviewToAllEdges(noConnectionCard)
            contentView.layoutIfNeeded()
        }
    }

    func createNoConnectionCard() -> UIView? {
        guard let context = blog?.managedObjectContext,
              let services = try? PublicizeService.allPublicizeServices(in: context) else {
            // Note: The context and publicize services are checked prior to this call in
            // `showNoConnectionView`. This scenario *shouldn't* be possible.
            assertionFailure("No managed object context or publicize services")
            let error = JetpackSocialError.noConnectionViewInvalidState
            CrashLogging.main.logError(error, userInfo: ["source": "social_dashboard_card"])
            return nil
        }
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
            guard let self,
                  let blog = self.blog,
                  let controller = SharingViewController(blog: blog, delegate: self) else {
                return
            }
            self.dashboardViewController?.navigationController?.pushViewController(controller, animated: true)
        }
    }

}

// MARK: - SharingViewControllerDelegate

extension DashboardJetpackSocialCardCell: SharingViewControllerDelegate {

    func didChangePublicizeServices() {
        dashboardViewController?.reloadCardsLocally()
    }

}
