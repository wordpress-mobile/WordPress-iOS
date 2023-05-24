import UIKit

final class FreeToPaidPlansDashboardCardCell: BaseDashboardDomainsCardCell {
    override var viewModel: DashboardDomainsCardViewModel {
        return cardViewModel
    }

    private lazy var cardViewModel: DashboardDomainsCardViewModel = {
        let onViewShow: () -> Void = { [weak self] in
            guard let self = self else {
                return
            }

            PlansTracker.trackFreeToPaidPlansDashboardCardShown(in: self.row)
        }

        let onViewTap: () -> Void = { [weak self] in
            guard let self,
                  let presentingViewController = self.presentingViewController,
                  let blog = self.blog else {
                return
            }

            FreeToPaidPlansCoordinator.presentFreeDomainWithAnnualPlanFlow(
                in: presentingViewController,
                source: Strings.source,
                blog: blog
            )

            PlansTracker.trackFreeToPaidPlansDashboardCardTapped(in: self.row)
        }

        let onEllipsisTap: () -> Void = { [weak self] in
            guard let self else {
                return
            }

            PlansTracker.trackFreeToPaidPlansDashboardCardMenuTapped(in: self.row)
        }

        let onHideThisTap: UIActionHandler = { [weak self] _ in
            guard let self else { return }

            FreeToPaidPlansDashboardCardHelper.hideCard(for: self.blog)
            PlansTracker.trackFreeToPaidPlansDashboardCardHidden(in: self.row)

            self.presentingViewController?.reloadCardsLocally()
        }

        return DashboardDomainsCardViewModel(
            strings: .init(
                title: Strings.title,
                description: Strings.description,
                hideThis: Strings.hideThis,
                source: Strings.source
            ),
            onViewShow: onViewShow,
            onViewTap: onViewTap,
            onEllipsisTap: onEllipsisTap,
            onHideThisTap: onHideThisTap
        )
    }()
}

extension FreeToPaidPlansDashboardCardCell {
    private enum Strings {
        static let title = NSLocalizedString("freeToPaidPlans.dashboard.card.shortTitle",
                                             value: "Free domain with an annual plan",
                                             comment: "Title for the Free to Paid plans dashboard card.")
        static let description = NSLocalizedString("freeToPaidPlans.dashboard.card.description",
                                                   value: "Get a free domain for the first year, remove ads on your site, and increase your storage.",
                                                   comment: "Description for the Free to Paid plans dashboard card.")
        static let hideThis = NSLocalizedString("freeToPaidPlans.dashboard.card.menu.hide",
                                                value: "Hide this",
                                                comment: "Title for a menu action in the context menu on the Free to Paid plans dashboard card.")
        static let source = "free_to_paid_plans_dashboard_card"
    }
}
