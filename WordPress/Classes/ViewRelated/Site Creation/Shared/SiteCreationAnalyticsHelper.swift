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

    // MARK: - Final Assembly
    static func trackSiteCreationSuccessLoading(_ siteDesign: RemoteSiteDesign?) {
        WPAnalytics.track(.enhancedSiteCreationSuccessLoading, withProperties: commonProperties(siteDesign))
    }

    static func trackSiteCreationSuccess(_ siteDesign: RemoteSiteDesign?) {
        WPAnalytics.track(.createdSite, withProperties: commonProperties(siteDesign))
    }

    static func trackSiteCreationSuccessPreviewViewed(_ siteDesign: RemoteSiteDesign?) {
        WPAnalytics.track(.enhancedSiteCreationSuccessPreviewViewed, withProperties: commonProperties(siteDesign))
    }

    static func trackSiteCreationSuccessLoaded(_ siteDesign: RemoteSiteDesign?) {
        WPAnalytics.track(.enhancedSiteCreationSuccessPreviewLoaded, withProperties: commonProperties(siteDesign))
    }

    static func trackSiteCreationSuccessPreviewOkButtonTapped() {
        WPAnalytics.track(.enhancedSiteCreationSuccessPreviewOkButtonTapped)
    }

    // MARK: - Error
    static func trackError(_ error: Error) {
        let errorProperties: [String: AnyObject] = [
            "error_info": error.localizedDescription as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationErrorShown, withProperties: errorProperties)
    }

    // MARK: - Common
    private static func commonProperties(_ siteDesign: RemoteSiteDesign?) -> [AnyHashable: Any] {
        guard let siteDesign = siteDesign else { return [:] }
        return  [siteDesignKey: siteDesign.slug]
    }
}
