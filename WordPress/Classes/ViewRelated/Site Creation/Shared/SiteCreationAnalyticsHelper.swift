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
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSelected, withProperties: [siteDesignKey: siteDesign.slug])
    }

    // MARK: - Site Design Preview
    static func trackSiteDesignPreviewViewed(_ siteDesign: RemoteSiteDesign) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewViewed, withProperties: [siteDesignKey: siteDesign.slug])
    }

    static func trackSiteDesignPreviewLoading() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewLoading)
    }

    static func trackSiteDesignPreviewLoaded() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewLoaded)
    }

    // MARK: - Error
    static func trackError(_ error: Error) {
        let errorProperties: [String: AnyObject] = [
            "error_info": error.localizedDescription as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationErrorShown, withProperties: errorProperties)
    }
}
