import UIKit

final class DashboardBlazeCardCell: DashboardCollectionViewCell {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        BlazeEventsTracker.trackEntryPointDisplayed(for: .dashboardCard)

        if RemoteFeatureFlag.blazeManageCampaigns.enabled() {
            // Display campaigns
            let cardView = DashboardBlazeCampaignsCardView()
            cardView.configure(blog: blog, viewController: viewController)
            setCardView(cardView, subtype: .campaigns)
        } else {
            // Display promo
            let cardView = DashboardBlazePromoCardView(.make(with: blog, viewController: viewController))
            setCardView(cardView, subtype: .promo)
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
