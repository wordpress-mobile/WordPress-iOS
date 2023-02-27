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
            // TODO: Track analytics event
            BlazeWebViewCoordinator.presentBlazeFlow(in: presentingViewController, source: .dashboardCard, blog: blog)
        }

        let onHideThisTap: UIActionHandler = { [weak self] _ in
            // TODO: Track analytics event
            BlazeHelper.hideBlazeCard(for: self?.blog)
            self?.presentingViewController?.reloadCardsLocally()
        }

        return BlazeCardViewModel(onViewTap: onViewTap, onHideThisTap: onHideThisTap)
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
    }
}
