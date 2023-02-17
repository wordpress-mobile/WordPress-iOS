import UIKit

class DashboardJetpackInstallCardCell: DashboardCollectionViewCell {

    // MARK: Properties

    private var blog: Blog?
    private weak var presenterViewController: BlogDashboardViewController?

    private lazy var cardViewModel: JetpackRemoteInstallCardViewModel = {
        let onHideThisTap: UIActionHandler = { [weak self] _ in
            JetpackInstallPluginHelper.hideCard(for: self?.blog)
            self?.presenterViewController?.reloadCardsLocally()
        }
        return JetpackRemoteInstallCardViewModel(onHideThisTap: onHideThisTap)
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
    }

    private func setupView() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: .defaultHigh)
    }

}
