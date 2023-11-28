import SwiftUI

final class BlogDashboardPersonalizationViewModel: ObservableObject {
    let quickActions: [DashboardPersonalizationQuickActionViewModel]
    let cards: [BlogDashboardPersonalizationCardCellViewModel]

    init(blog: Blog, service: BlogDashboardPersonalizationService) {
        self.quickActions = DashboardQuickAction.personalizableActions
            .filter { $0.isEligible(for: blog) }
            .map {
                DashboardPersonalizationQuickActionViewModel(action: $0, service: service)
            }
        self.cards = DashboardCard.personalizableCards.map {
            BlogDashboardPersonalizationCardCellViewModel(
                card: $0,
                title: $0.getLocalizedTitle(),
                service: service
            )
        }
    }
}

final class DashboardPersonalizationQuickActionViewModel: ObservableObject, Identifiable {
    private let action: DashboardQuickAction
    private let service: BlogDashboardPersonalizationService

    var id: DashboardQuickAction { action }
    let image: UIImage?
    let title: String

    var isOn: Bool {
        get { service.isEnabled(action) }
        set {
            objectWillChange.send()
            service.setEnabled(newValue, for: action)
        }
    }

    init(action: DashboardQuickAction, service: BlogDashboardPersonalizationService) {
        self.action = action
        self.image = action.image
        self.title = action.localizedTitle
        self.service = service
    }
}

final class BlogDashboardPersonalizationCardCellViewModel: ObservableObject, Identifiable {
    private let card: DashboardCard
    private let service: BlogDashboardPersonalizationService

    var id: DashboardCard { card }
    let title: String

    var isOn: Bool {
        get { service.isEnabled(card) }
        set {
            objectWillChange.send()
            service.setEnabled(newValue, for: card)
        }
    }

    init(card: DashboardCard, title: String, service: BlogDashboardPersonalizationService) {
        self.card = card
        self.title = title
        self.service = service
    }
}

private extension DashboardCard {
    func getLocalizedTitle() -> String {
        switch self {
        case .prompts:
            return NSLocalizedString("personalizeHome.dashboardCard.prompts", value: "Blogging prompts", comment: "Card title for the pesonalization menu")
        case .blaze:
            return NSLocalizedString("personalizeHome.dashboardCard.blaze", value: "Blaze", comment: "Card title for the pesonalization menu")
        case .todaysStats:
            return NSLocalizedString("personalizeHome.dashboardCard.todaysStats", value: "Today's stats", comment: "Card title for the pesonalization menu")
        case .draftPosts:
            return NSLocalizedString("personalizeHome.dashboardCard.draftPosts", value: "Draft posts", comment: "Card title for the pesonalization menu")
        case .scheduledPosts:
            return NSLocalizedString("personalizeHome.dashboardCard.scheduledPosts", value: "Scheduled posts", comment: "Card title for the pesonalization menu")
        case .activityLog:
            return NSLocalizedString("personalizeHome.dashboardCard.activityLog", value: "Recent activity", comment: "Card title for the pesonalization menu")
        case .pages:
            return NSLocalizedString("personalizeHome.dashboardCard.pages", value: "Pages", comment: "Card title for the pesonalization menu")
        case .quickStart, .ghost, .failure, .personalize, .jetpackBadge, .jetpackInstall, .empty, .freeToPaidPlansDashboardCard, .domainRegistration, .jetpackSocial, .bloganuaryNudge, .googleDomains:
            assertionFailure("\(self) card should not appear in the personalization menus")
            return "" // These cards don't appear in the personalization menus
        }
    }
}
