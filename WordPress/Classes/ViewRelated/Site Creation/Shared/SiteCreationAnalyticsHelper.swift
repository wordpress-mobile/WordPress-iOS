import Foundation
import WordPressKit

class SiteCreationAnalyticsHelper {
    private static let siteDesignKey = "template"

    static func trackSiteDesignViewed() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignViewed)
    }

    static func trackSiteDesignSkipped() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSkipped)
    }

    static func trackSiteDesignSelected(_ siteDesign: RemoteSiteDesign) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSelected, withProperties: [siteDesignKey: siteDesign.slug])
    }

    static func trackError(_ error: Error) {
        let errorProperties: [String: AnyObject] = [
            "error_info": error.localizedDescription as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationErrorShown, withProperties: errorProperties)
    }
}
