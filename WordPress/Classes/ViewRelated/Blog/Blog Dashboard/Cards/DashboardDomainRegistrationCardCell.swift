import UIKit
import WordPressFlux

final class DashboardDomainRegistrationCardCell: BaseDashboardDomainsCardCell {

    // MARK: - View Model

    override var viewModel: DashboardDomainsCardViewModel {
        return cardViewModel
    }

    private lazy var cardViewModel: DashboardDomainsCardViewModel = {
        let onViewTap: () -> Void = { [weak self] in
            self?.cardTapped()
        }
        let onHideThisTap: UIActionHandler = { [weak self] _ in
            self?.hideCardTapped()
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

    private func cardTapped() {
        guard let props = makeUnwrappedProperties() else {
            return
        }
        WPAnalytics.track(.domainCreditRedemptionTapped)
        DomainsDashboardCoordinator.presentDomainsSuggestions(
            in: props.presentingViewController,
            source: Strings.source,
            blog: props.blog
        )
    }

    private func hideCardTapped() {
        guard let props = makeUnwrappedProperties() else {
            return
        }
        let service = BlogDashboardPersonalizationService(siteID: props.siteID.intValue)
        service.setEnabled(false, for: .domainRegistration)
    }

    // MARK: - Constants

    private static var hasLoggedDomainCreditPromptShownEvent: Bool = false

    // MARK: - View Lifecycle

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !Self.hasLoggedDomainCreditPromptShownEvent else {
            return
        }
        WPAnalytics.track(WPAnalyticsStat.domainCreditPromptShown)
        Self.hasLoggedDomainCreditPromptShownEvent = true
    }

    // MARK: - Helpers

    private func makeUnwrappedProperties() -> Unwrapped? {
        return Unwrapped(presentingViewController: presentingViewController, blog: blog)
    }

    // MARK: - Supporting Types

    /// Encapsulates the unwrapping logic and returns nil if one of the passed in parameters is nil.
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

// MARK: - Extensions

extension DashboardDomainRegistrationCardCell {

    private enum Strings {
        static let title = NSLocalizedString(
            "Register Domain",
            comment: "Action to redeem domain credit."
        )
        static let content = NSLocalizedString(
            "All WordPress.com annual plans include a custom domain name. Register your free domain now.",
            comment: "Information about redeeming domain credit on site dashboard."
        )
        static let hideThis = NSLocalizedString(
            "domain.dashboard.card.menu.hide",
            value: "Hide this",
            comment: "Title for a menu action in the context menu on the Jetpack install card."
        )
        static let source = "domain_registration_dashboard_card"
    }
}
