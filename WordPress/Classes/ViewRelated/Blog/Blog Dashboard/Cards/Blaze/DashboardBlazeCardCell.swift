import UIKit

final class DashboardBlazeCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController
        BlazeEventsTracker.trackEntryPointDisplayed(for: .dashboardCard)

        contentView.subviews.forEach { $0.removeFromSuperview() }
        let cardView = DashboardBlazePromoCardView(.make(with: blog, viewController: viewController))
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: UILayoutPriority(999))
    }
}
