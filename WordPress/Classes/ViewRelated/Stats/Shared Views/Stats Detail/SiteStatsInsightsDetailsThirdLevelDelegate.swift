import Foundation

/// used when StatsInsightsDetails screen has a 3rd level
@objc protocol SiteStatsInsightsDetailsThirdLevelDelegate {

    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
}
