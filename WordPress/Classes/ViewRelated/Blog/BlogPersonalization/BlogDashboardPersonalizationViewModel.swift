import SwiftUI

final class BlogDashboardPersonalizationViewModel: ObservableObject {
    let cards: [BlogDashboardPersonalizationCardCellViewModel]

    init(service: BlogDashboardPersonalizationService) {
        self.cards = DashboardCard.personalizableCards.map {
            BlogDashboardPersonalizationCardCellViewModel(card: $0, service: service)
        }
    }
}

final class BlogDashboardPersonalizationCardCellViewModel: ObservableObject, Identifiable {
    private let card: DashboardCard
    private let service: BlogDashboardPersonalizationService

    var id: DashboardCard { card }
    var title: String { card.localizedTitle }

    var isOn: Bool {
        get { service.isEnabled(card) }
        set {
            objectWillChange.send()
            service.setEnabled(newValue, for: card)
        }
    }

    init(card: DashboardCard, service: BlogDashboardPersonalizationService) {
        self.card = card
        self.service = service
    }
}

private extension DashboardCard {
    var localizedTitle: String {
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
        case .quickStart, .nextPost, .createPost, .ghost, .failure, .personalize, .jetpackBadge, .jetpackInstall, .domainsDashboardCard, .freeToPaidPlansDashboardCard, .empty:
            assertionFailure("\(self) card should not appear in the personalization menus")
            return "" // These cards don't appear in the personalization menus
        }
    }
}
