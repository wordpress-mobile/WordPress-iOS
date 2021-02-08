import Foundation
import WordPressKit

class SiteCreationAnalyticsHelper {
    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice

    private static let siteDesignKey = "template"
    private static let previewModeKey = "preview_mode"

    // MARK: - Site Design
    static func trackSiteDesignViewed(previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignViewed, withProperties: commonProperties(previewMode))
    }

    static func trackSiteDesignThumbnailModeButtonTapped(_ previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignThumbnailModeButtonTapped, withProperties: commonProperties(previewMode))
    }

    static func trackSiteDesignSkipped() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSkipped)
    }

    static func trackSiteDesignSelected(_ siteDesign: RemoteSiteDesign) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSelected, withProperties: commonProperties(siteDesign))
    }

    // MARK: - Site Design Preview
    static func trackSiteDesignPreviewViewed(siteDesign: RemoteSiteDesign, previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewViewed, withProperties: commonProperties(siteDesign, previewMode))
    }

    static func trackSiteDesignPreviewLoading(siteDesign: RemoteSiteDesign, previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewLoading, withProperties: commonProperties(siteDesign, previewMode))
    }

    static func trackSiteDesignPreviewLoaded(siteDesign: RemoteSiteDesign, previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewLoaded, withProperties: commonProperties(previewMode, siteDesign))
    }

    static func trackSiteDesignPreviewModeButtonTapped(_ previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewModeButtonTapped, withProperties: commonProperties(previewMode))
    }

    static func trackSiteDesignPreviewModeChanged(_ previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignPreviewModeChanged, withProperties: commonProperties(previewMode))
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
    private static func commonProperties(_ properties: Any?...) -> [AnyHashable: Any] {
        var result: [AnyHashable: Any] = [:]

        for property: Any? in properties {
            if let siteDesign = property as? RemoteSiteDesign {
                result.merge([siteDesignKey: siteDesign.slug]) { (_, new) in new }
            }
            if let previewMode = property as? PreviewDevice {
                result.merge([previewModeKey: previewMode.rawValue]) { (_, new) in new }
            }
        }

        return result
    }
}
