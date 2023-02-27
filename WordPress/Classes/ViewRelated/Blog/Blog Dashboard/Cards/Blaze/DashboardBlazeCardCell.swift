import UIKit

class DashboardBlazeCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Views

    private lazy var cardViewModel: BlazeCardViewModel = {
        let onHideThisTap: UIActionHandler = { [weak self] _ in
            // TODO: Track analytics event
            BlazeHelper.hideBlazeCard(for: self?.blog)
            self?.presentingViewController?.reloadCardsLocally()
        }

        return BlazeCardViewModel(onHideThisTap: onHideThisTap)
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

    func setupView() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: .defaultHigh)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController
    }
}
