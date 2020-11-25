import Foundation
import WordPressKit

class SiteCreationAnalyticsHelper {
    private static let siteDesignKey = "template"

    // MARK: - Site Design
    static func trackSiteDesignViewed() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignViewed)
    }

    static func trackSiteDesignSkipped() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSkipped)
    }

    static func trackSiteDesignSelected(_ siteDesign: RemoteSiteDesign) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSelected, withProperties: commonProperties(siteDesign))
    }

    // MARK: - Site Design Preview
    static func trackSiteDesignPreviewViewed(_ siteDesign: RemoteSiteDesign) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewViewed, withProperties: commonProperties(siteDesign))
    }

    static func trackSiteDesignPreviewLoading(_ siteDesign: RemoteSiteDesign) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewLoading, withProperties: commonProperties(siteDesign))
    }

    static func trackSiteDesignPreviewLoaded(_ siteDesign: RemoteSiteDesign) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewLoaded, withProperties: commonProperties(siteDesign))
    }

    // MARK: - Error
    static func trackError(_ error: Error) {
        let errorProperties: [String: AnyObject] = [
            "error_info": error.localizedDescription as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationErrorShown, withProperties: errorProperties)
    }

    // MARK: - Common
    private static func commonProperties(_ siteDesign: RemoteSiteDesign) -> [AnyHashable: Any] {
        return  [siteDesignKey: siteDesign.slug]
    }
}
