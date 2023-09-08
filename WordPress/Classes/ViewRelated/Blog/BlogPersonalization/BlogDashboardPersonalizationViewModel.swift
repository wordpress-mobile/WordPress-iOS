import SwiftUI

final class BlogDashboardPersonalizationViewModel: ObservableObject {
    let quickActions: [DashboardPersonalizationQuickActionViewModel]
    let cards: [BlogDashboardPersonalizationCardCellViewModel]

    init(blog: Blog, service: BlogDashboardPersonalizationService, quickStartType: QuickStartType) {
        self.quickActions = DashboardQuickAction.personalizableActions
            .filter { $0.isEligible(for: blog) }
            .map {
                DashboardPersonalizationQuickActionViewModel(action: $0, service: service)
            }
        self.cards = DashboardCard.personalizableCards.compactMap {
            if $0 == .quickStart && quickStartType == .undefined {
                return nil
            }
            let title = $0.getLocalizedTitle(quickStartType: quickStartType)
            return BlogDashboardPersonalizationCardCellViewModel(card: $0, title: title, service: service)
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
    func getLocalizedTitle(quickStartType: QuickStartType) -> String {
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
        case .quickStart:
            switch quickStartType {
            case .undefined:
                assertionFailure(".quickStart card should only appear in the personalization menu if there are remaining steps")
                return ""
            case .existingSite:
                return NSLocalizedString("personalizeHome.dashboardCard.getToKnowTheApp", value: "Get to know the app", comment: "Card title for the pesonalization menu")
            case .newSite:
                return NSLocalizedString("personalizeHome.dashboardCard.nextSteps", value: "Next steps", comment: "Card title for the pesonalization menu")
            }
        case .ghost, .failure, .personalize, .jetpackBadge, .jetpackInstall, .empty, .domainsDashboardCard, .freeToPaidPlansDashboardCard, .domainRegistration, .jetpackSocial, .googleDomains:
            assertionFailure("\(self) card should not appear in the personalization menus")
            return "" // These cards don't appear in the personalization menus
        }
    }
}
