import UIKit
import WordPressFlux

final class DashboardRegisterDomainCardCell: BaseDashboardDomainsCardCell {

    override var viewModel: DashboardDomainsCardViewModel {
        return cardViewModel
    }

    private lazy var cardViewModel: DashboardDomainsCardViewModel = {
        let onViewTap: () -> Void = { [weak self] in
        }
        let onEllipsisTap: () -> Void = { [weak self] in
        }
        let onHideThisTap: UIActionHandler = { [weak self] _ in
        }
        return DashboardDomainsCardViewModel(
            strings: .init(
                title: Strings.title,
                description: Strings.content,
                hideThis: Strings.hideThis,
                source: Strings.source
            ),
            onViewTap: onViewTap,
            onEllipsisTap: onEllipsisTap,
            onHideThisTap: onHideThisTap
        )
    }()

    // MARK: - User Interaction

    // MARK: - Constants

    private static var hasLoggedDomainCreditPromptShownEvent: Bool = false

    private enum Strings {
        static let title = NSLocalizedString(
            "Register Domain",
            comment: "Action to redeem domain credit."
        )
        static let content = NSLocalizedString(
            "All WordPress.com plans include a custom domain name. Register your free premium domain now.",
            comment: "Information about redeeming domain credit on site dashboard."
        )
        static let hideThis = NSLocalizedString(
            "domain.dashboard.card.menu.hide",
            value: "Hide this",
            comment: "Title for a menu action in the context menu on the Jetpack install card."
        )
        static let source = "domain_registration_dashboard_card"
    }

    // MARK: - View Lifecycle

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !Self.hasLoggedDomainCreditPromptShownEvent else {
            return
        }
        WPAnalytics.track(WPAnalyticsStat.domainCreditPromptShown)
        Self.hasLoggedDomainCreditPromptShownEvent = true
    }
}
