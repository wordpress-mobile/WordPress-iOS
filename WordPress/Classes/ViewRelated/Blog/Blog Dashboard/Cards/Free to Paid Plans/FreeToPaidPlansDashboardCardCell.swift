import UIKit

final class FreeToPaidPlansDashboardCardCell: BaseDashboardDomainsCardCell {
    override var viewModel: DashboardDomainsCardViewModel {
        return cardViewModel
    }

    private lazy var cardViewModel: DashboardDomainsCardViewModel = {
        let onViewTap: () -> Void = { [weak self] in
            // TODO: Present Domain Selection
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/20686

            // TODO: Analytics
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/20692
        }

        let onEllipsisTap: () -> Void = { [weak self] in
            // TODO: Analytics
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/20692
        }

        let onHideThisTap: UIActionHandler = { [weak self] _ in
            guard let self else { return }

            FreeToPaidPlansDashboardCardHelper.hideCard(for: self.blog)

            // TODO: Analytics
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/20692

            self.presentingViewController?.reloadCardsLocally()
        }

        return DashboardDomainsCardViewModel(
            strings: .init(
                title: Strings.title,
                description: Strings.description,
                hideThis: Strings.hideThis,
                source: Strings.source
            ),
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
