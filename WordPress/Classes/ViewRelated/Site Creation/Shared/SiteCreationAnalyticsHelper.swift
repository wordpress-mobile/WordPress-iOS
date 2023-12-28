import Foundation
import WordPressKit
import AutomatticTracks

extension Variation {
    var tracksProperty: String {
        switch self {
        case .treatment:
            return "treatment"
        case .customTreatment:
            return "custom_treatment"
        case .control:
            return "control"
        }
    }
}

class SiteCreationAnalyticsHelper {
    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice

    private static let siteDesignKey = "template"
    private static let previewModeKey = "preview_mode"
    private static let verticalSlugKey = "vertical_slug"
    private static let verticalSearchTerm = "search_term"
    private static let variationKey = "variation"
    private static let siteNameKey = "site_name"
    private static let recommendedKey = "recommended"
    private static let customTreatmentNameKey = "custom_treatment_variation_name"

    // MARK: - Lifecycle
    static func trackSiteCreationAccessed(source: String) {
        WPAnalytics.track(.enhancedSiteCreationAccessed, withProperties: ["source": source])
    }

    // MARK: - Site Intent
    static func trackSiteIntentViewed() {
        WPAnalytics.track(.enhancedSiteCreationIntentQuestionViewed)
    }

    static func trackSiteIntentSelected(_ vertical: SiteIntentVertical) {
        let properties = [verticalSlugKey: vertical.slug]
        let event: WPAnalyticsEvent = vertical.isCustom ?
            .enhancedSiteCreationIntentQuestionCustomVerticalSelected :
            .enhancedSiteCreationIntentQuestionVerticalSelected

        WPAnalytics.track(event, properties: properties)
    }

    static func trackSiteIntentSearchFocused() {
        WPAnalytics.track(.enhancedSiteCreationIntentQuestionSearchFocused)
    }

    static func trackSiteIntentSkipped() {
        WPAnalytics.track(.enhancedSiteCreationIntentQuestionSkipped)
    }

    static func trackSiteIntentCanceled() {
        WPAnalytics.track(.enhancedSiteCreationIntentQuestionCanceled)
    }

    // MARK: - Site Name
    static func trackSiteNameViewed() {
        WPAnalytics.track(.enhancedSiteCreationSiteNameViewed)
    }

    static func trackSiteNameEntered(_ name: String) {
        let properties = [siteNameKey: name]
        WPAnalytics.track(.enhancedSiteCreationSiteNameEntered, properties: properties)
    }

    static func trackSiteNameSkipped() {
        WPAnalytics.track(.enhancedSiteCreationSiteNameSkipped)
    }

    // MARK: - Site Design
    static func trackSiteDesignViewed(previewMode: PreviewDevice) {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignViewed, withProperties: commonProperties(previewMode))
    }

    static func trackSiteDesignSkipped() {
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSkipped)
    }

    static func trackSiteDesignSelected(_ siteDesign: RemoteSiteDesign, sectionType: SiteDesignSectionType) {
        var properties = commonProperties(siteDesign)
        properties[recommendedKey] = sectionType == .recommended
        WPAnalytics.track(.enhancedSiteCreationSiteDesignSelected, withProperties: properties)
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
