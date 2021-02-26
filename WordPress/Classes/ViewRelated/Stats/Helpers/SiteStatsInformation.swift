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

    func updateTimeZone() {
        let context = ContextManager.shared.mainContext

        guard let siteID = siteID, let blog = Blog.lookup(withID: siteID, in: context) else {
            return
        }

        siteTimeZone = blog.timeZone
    }

    func timeZoneMatchesDevice() -> Bool {
        return siteTimeZone == TimeZone.current
    }

}
