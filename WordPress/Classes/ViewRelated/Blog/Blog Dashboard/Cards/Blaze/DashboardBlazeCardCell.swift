import UIKit
import WordPressKit

final class DashboardBlazeCardCell: DashboardCollectionViewCell {
    private var blog: Blog?
    private var viewController: BlogDashboardViewController?
    private var viewModel: DashboardBlazeCardCellViewModel?

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.viewController = viewController

        BlazeEventsTracker.trackEntryPointDisplayed(for: .dashboardCard)
    }

    func configure(_ viewModel: DashboardBlazeCardCellViewModel) {
        guard viewModel !== self.viewModel else { return }
        self.viewModel = viewModel

        viewModel.onRefresh = { [weak self] in
            self?.update(with: $0)
            self?.viewController?.collectionView.collectionViewLayout.invalidateLayout()
        }
        update(with: viewModel)
    }

    private func update(with viewModel: DashboardBlazeCardCellViewModel) {
        guard let blog, let viewController else { return }

        if let campaign = viewModel.lastestCampaign {
            // Display campaigns
            let cardView = DashboardBlazeCampaignsCardView()
            cardView.configure(blog: blog, viewController: viewController, campaign: campaign)
            self.setCardView(cardView, subtype: .campaigns)
        } else {
            // Display promo
            let cardView = DashboardBlazePromoCardView(.make(with: blog, viewController: viewController))
            self.setCardView(cardView, subtype: .promo)
        }
    }

    private func setCardView(_ cardView: UIView, subtype: DashboardBlazeCardSubtype) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: UILayoutPriority(999))

        BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: [
            "type": DashboardCard.blaze.rawValue,
            "sub_type": subtype.rawValue
        ])
    }
}

enum DashboardBlazeCardSubtype: String {
    case promo = "no_campaigns"
    case campaigns = "campaigns"
}
