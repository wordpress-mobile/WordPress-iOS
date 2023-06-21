import UIKit

final class DashboardBlazeCardCell: DashboardCollectionViewCell {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        BlazeEventsTracker.trackEntryPointDisplayed(for: .dashboardCard)

        if RemoteFeature.enabled(.blazeManageCampaigns) {
            // Display campaigns
            let cardView = DashboardBlazeCampaignsCardView()
            cardView.configure(blog: blog, viewController: viewController)
            setCardView(cardView)
        } else {
            // Display promo
            let cardView = DashboardBlazePromoCardView(.make(with: blog, viewController: viewController))
            setCardView(cardView)
        }
    }

    private func setCardView(_ cardView: UIView) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: UILayoutPriority(999))
    }
}
