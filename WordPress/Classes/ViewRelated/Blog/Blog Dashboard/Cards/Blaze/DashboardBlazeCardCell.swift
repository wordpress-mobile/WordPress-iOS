import UIKit

class DashboardBlazeCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Views

    private lazy var cardViewModel: BlazeCardViewModel = {

        let onViewTap: () -> Void = { [weak self] in
            guard let presentingViewController = self?.presentingViewController,
                  let blog = self?.blog else {
                return
            }
            BlazeEventsTracker.trackEntryPointTapped(for: .dashboardCard)
            BlazeOverlayCoordinator.presentBlazeOverlay(in: presentingViewController, source: .dashboardCard, blog: blog)
        }

        let onEllipsisTap: () -> Void = { [weak self] in
            BlazeEventsTracker.trackContextualMenuAccessed(for: .dashboardCard)
        }

        let onHideThisTap: UIActionHandler = { [weak self] _ in
            BlazeEventsTracker.trackHideThisTapped(for: .dashboardCard)
            BlazeHelper.hideBlazeCard(for: self?.blog)
            self?.presentingViewController?.reloadCardsLocally()
        }

        return BlazeCardViewModel(onViewTap: onViewTap,
                                  onEllipsisTap: onEllipsisTap,
                                  onHideThisTap: onHideThisTap)
    }()

    private lazy var cardView: BlazeCardView = {
        let cardView = BlazeCardView(cardViewModel)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        return cardView
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    private func setupView() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: .defaultHigh)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController
        BlazeEventsTracker.trackEntryPointDisplayed(for: .dashboardCard)
    }
}
