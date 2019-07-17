import Foundation

/// Singleton class to contain site related information for Stats.
///
@objc class SiteStatsInformation: NSObject {

    // MARK: - Properties

    @objc static var sharedInstance: SiteStatsInformation = SiteStatsInformation()
    private override init() {}

    @objc var siteID: NSNumber?
    @objc var siteTimeZone: TimeZone?
    @objc var oauth2Token: String?

    func timeZoneMatchesDevice() -> Bool {
        return siteTimeZone == TimeZone.current
    }

}
