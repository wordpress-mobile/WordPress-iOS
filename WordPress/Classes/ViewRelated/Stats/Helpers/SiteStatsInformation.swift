import Foundation
import WordPressComStatsiOS

/// Singleton class to contain site related information for Stats.
///
@objc class SiteStatsInformation: NSObject {

    // MARK: - Properties

    @objc static var sharedInstance: SiteStatsInformation = SiteStatsInformation()

    @objc var siteID: NSNumber?
    @objc var siteTimeZone: TimeZone?
    @objc var oauth2Token: String?

    static let cacheExpirationInterval = Double(300)

    // MARK: - Instance Methods

    static func statsService() -> WPStatsService? {

        guard let siteID = SiteStatsInformation.sharedInstance.siteID,
            let siteTimeZone = SiteStatsInformation.sharedInstance.siteTimeZone,
            let oauth2Token = SiteStatsInformation.sharedInstance.oauth2Token else {
                return nil
        }

        return WPStatsService.init(siteId: siteID,
                                   siteTimeZone: siteTimeZone,
                                   oauth2Token: oauth2Token,
                                   andCacheExpirationInterval: SiteStatsInformation.cacheExpirationInterval)
    }

}
