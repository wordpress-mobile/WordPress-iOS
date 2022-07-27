import Foundation

// A protocol to constrain Site Stats pinned items together
protocol SiteStatsPinnable { /* not implemented */ }

final class SiteStatsPinnedItemStore {
    private lazy var items: [SiteStatsPinnable] = {
        return [
            GrowAudienceCell.HintType.social,
            GrowAudienceCell.HintType.bloggingReminders,
            GrowAudienceCell.HintType.readerDiscover,
            InsightType.customize
        ]
    }()
    private let lowSiteViewsCountThreshold = 3000
    private let siteId: NSNumber
    private(set) var currentItem: SiteStatsPinnable?

    init(siteId: NSNumber) {
        self.siteId = siteId
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
        UserDefaults.standard.set(true, forKey: userDefaultsKey(for: item))
    }

    func shouldShow(_ item: SiteStatsPinnable) -> Bool {
        !UserDefaults.standard.bool(forKey: userDefaultsKey(for: item))
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
