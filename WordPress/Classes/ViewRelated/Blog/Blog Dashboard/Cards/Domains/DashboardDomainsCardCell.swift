import UIKit

final class DashboardDomainsCardCell: BaseDashboardDomainsCardCell {
    override var viewModel: DashboardDomainsCardViewModel {
        return cardViewModel
    }

    private lazy var cardViewModel: DashboardDomainsCardViewModel = {
        let onViewShow: () -> Void = { [weak self] in
            guard let self = self else {
                return
            }

            DomainsDashboardCardTracker.trackDirectDomainsPurchaseDashboardCardShown(in: self.row)
        }

        let onViewTap: () -> Void = { [weak self] in
            guard let self,
                  let presentingViewController = self.presentingViewController,
                  let blog = self.blog else {
                return
            }

            DomainsDashboardCoordinator.presentDomainsSuggestions(in: presentingViewController,
                                                                  source: Strings.source,
                                                                  blog: blog)
            DomainsDashboardCardTracker.trackDirectDomainsPurchaseDashboardCardTapped(in: self.row)
        }

        let onEllipsisTap: () -> Void = { [weak self] in
        }

        let onHideThisTap: UIActionHandler = { [weak self] _ in
            guard let self else { return }

            DomainsDashboardCardHelper.hideCard(for: self.blog)
            DomainsDashboardCardTracker.trackDirectDomainsPurchaseDashboardCardHidden(in: self.row)
            self.presentingViewController?.reloadCardsLocally()
        }

        return DashboardDomainsCardViewModel(
            strings: .init(
                title: Strings.title,
                description: Strings.description,
                hideThis: Strings.hideThis,
                source: Strings.source,
                accessibilityIdentifier: Strings.accessibilityIdentifier
            ),
            onViewShow: onViewShow,
            onViewTap: onViewTap,
            onEllipsisTap: onEllipsisTap,
            onHideThisTap: onHideThisTap
        )
    }()
}

extension DashboardDomainsCardCell {
    private enum Strings {
        static let title = NSLocalizedString("domain.dashboard.card.shortTitle",
                                             value: "Find a custom domain",
                                             comment: "Title for the Domains dashboard card.")
        static let description = NSLocalizedString("domain.dashboard.card.description",
                                                   value: "Stake your claim on your corner of the web with a site address that’s easy to find, share and follow.",
                                                   comment: "Description for the Domains dashboard card.")
        static let hideThis = NSLocalizedString("domain.dashboard.card.menu.hide",
                                                value: "Hide this",
                                                comment: "Title for a menu action in the context menu on the Jetpack install card.")
        static let source = "domains_dashboard_card"
        static let accessibilityIdentifier = "dashboard-domains-card-contentview"
    }
}
