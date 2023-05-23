import UIKit
import WordPressFlux

final class DashboardRegisterDomainCardCell: BaseDashboardDomainsCardCell {

    override var viewModel: DashboardDomainsCardViewModel {
        return cardViewModel ?? .empty
    }

    private lazy var cardViewModel: DashboardDomainsCardViewModel? = {
        guard let props = Unwrapped(presentingViewController: presentingViewController, blog: blog) else {
            return nil
        }
        let onViewTap: () -> Void = { [weak self] in
            self?.cardTapped(props: props)
        }
        let onHideThisTap: UIActionHandler = { [weak self] _ in
            self?.hideCardTapped(props: props)
        }
        return DashboardDomainsCardViewModel(
            strings: .init(
                title: Strings.title,
                description: Strings.content,
                hideThis: Strings.hideThis,
                source: Strings.source
            ),
            onViewTap: onViewTap,
            onHideThisTap: onHideThisTap
        )
    }()

    // MARK: - User Interaction

    private func cardTapped(props: Unwrapped) {
        WPAnalytics.track(.domainCreditRedemptionTapped)
        DomainsDashboardCoordinator.presentDomainsSuggestions(
            in: props.presentingViewController,
            source: Strings.source,
            blog: props.blog
        )
    }

    private func hideCardTapped(props: Unwrapped) {
        let service = BlogDashboardPersonalizationService(siteID: props.siteID.intValue)
        service.setEnabled(false, for: .registerDomain)
    }

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

    // MARK: - Supporting Types

    private struct Unwrapped {

        let presentingViewController: BlogDashboardViewController
        let blog: Blog
        let siteID: NSNumber

        init?(presentingViewController: BlogDashboardViewController?,
             blog: Blog?) {
            guard let presentingViewController,
                  let blog,
                  let siteID = blog.dotComID else {
                return nil
            }
            self.presentingViewController = presentingViewController
            self.blog = blog
            self.siteID = siteID
        }
    }
}
