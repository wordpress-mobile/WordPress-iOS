import Foundation

// A protocol to constrain Site Stats pinned items together
protocol SiteStatsPinnable { /* not implemented */ }

final class SiteStatsPinnedItemStore {
    private(set) lazy var items: [SiteStatsPinnable] = {
        let presentBloggingReminders = jetpackNotificationMigrationService.shouldPresentNotifications()
        return presentBloggingReminders ?
            [GrowAudienceCell.HintType.social,
             GrowAudienceCell.HintType.bloggingReminders,
             GrowAudienceCell.HintType.readerDiscover,
             InsightType.customize] :
            [GrowAudienceCell.HintType.social,
             GrowAudienceCell.HintType.readerDiscover,
             InsightType.customize]
    }()
    private let lowSiteViewsCountThreshold = 3000
    private let siteId: NSNumber
    private(set) var currentItem: SiteStatsPinnable?
    private let jetpackNotificationMigrationService: JetpackNotificationMigrationServiceProtocol

    init(siteId: NSNumber,
         jetpackNotificationMigrationService: JetpackNotificationMigrationServiceProtocol = JetpackNotificationMigrationService.shared) {
        self.siteId = siteId
        self.jetpackNotificationMigrationService = jetpackNotificationMigrationService
    }

    func itemToDisplay(for siteViewsCount: Int) -> SiteStatsPinnable? {
        if siteViewsCount < lowSiteViewsCountThreshold {
            currentItem = nudgeToDisplay ?? customizeToDisplay
        } else {
            currentItem = customizeToDisplay
        }
        return currentItem
    }

    func markPinnedItemAsHidden(_ item: SiteStatsPinnable) {
        UserPersistentStoreFactory.instance().set(true, forKey: userDefaultsKey(for: item))
    }

    func shouldShow(_ item: SiteStatsPinnable) -> Bool {
        !UserPersistentStoreFactory.instance().bool(forKey: userDefaultsKey(for: item))
    }
}

// MARK: - Private Methods
private extension SiteStatsPinnedItemStore {
    var nudgeToDisplay: SiteStatsPinnable? {
        for item in items where item is GrowAudienceCell.HintType && shouldShow(item) {
            return item
        }
        return nil
    }

    var customizeToDisplay: SiteStatsPinnable? {
        let item = InsightType.customize
        return shouldShow(item) ? item : nil
    }

    // Keys for 'nudge' items are site specific
    // Key for 'customize' item is global
    func userDefaultsKey(for item: SiteStatsPinnable) -> String {
        switch item {
        case is GrowAudienceCell.HintType:
            let item = item as! GrowAudienceCell.HintType
            return "StatsInsights-\(siteId.intValue)-\(item.userDefaultsKey)-isHidden"
        case InsightType.customize:
            return "StatsInsightsHideCustomizeCard"
        default:
            fatalError("SiteStatsPinnable of unknown type!")
        }
    }
}
