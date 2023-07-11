import Foundation

@objcMembers class BlazeEventsTracker: NSObject {

    private static let currentStepPropertyKey = "current_step"
    private static let errorPropertyKey = "error"

    static func trackEntryPointDisplayed(for source: BlazeSource) {
        WPAnalytics.track(.blazeEntryPointDisplayed, properties: analyticsProperties(for: source))
    }

    static func trackEntryPointTapped(for source: BlazeSource) {
        WPAnalytics.track(.blazeEntryPointTapped, properties: analyticsProperties(for: source))
    }

    // MARK: - Dashboard card

    static func trackContextualMenuAccessed(for source: BlazeSource) {
        WPAnalytics.track(.blazeContextualMenuAccessed, properties: analyticsProperties(for: source))
    }

    static func trackHideThisTapped(for source: BlazeSource) {
        WPAnalytics.track(.blazeCardHidden, properties: analyticsProperties(for: source))
    }

    // MARK: - Overlay

    static func trackOverlayDisplayed(for source: BlazeSource) {
        WPAnalytics.track(.blazeOverlayDisplayed, properties: analyticsProperties(for: source))
    }

    static func trackOverlayButtonTapped(for source: BlazeSource) {
        WPAnalytics.track(.blazeOverlayButtonTapped, properties: analyticsProperties(for: source))
    }

    static func trackOverlayDismissed(for source: BlazeSource) {
        WPAnalytics.track(.blazeOverlayDismissed, properties: analyticsProperties(for: source))
    }

    // MARK: - Blaze webview flow

    static func trackBlazeFlowStarted(for source: BlazeSource) {
        WPAnalytics.track(.blazeFlowStarted, properties: analyticsProperties(for: source))
    }

    static func trackBlazeFlowCompleted(for source: BlazeSource, currentStep: String) {
        WPAnalytics.track(.blazeFlowCompleted, properties: analyticsProperties(for: source, currentStep: currentStep))
    }

    static func trackBlazeFlowCanceled(for source: BlazeSource, currentStep: String) {
        WPAnalytics.track(.blazeFlowCanceled, properties: analyticsProperties(for: source, currentStep: currentStep))
    }

    static func trackBlazeFlowError(for source: BlazeSource, currentStep: String, error: Error? = nil) {
        var properties = analyticsProperties(for: source, currentStep: currentStep)
        if let error {
            properties[Self.errorPropertyKey] = error.localizedDescription
        }
        WPAnalytics.track(.blazeFlowError, properties: properties)
    }

    // MARK: - Campaign list

    static func trackCampaignListOpened(for source: BlazeSource) {
        WPAnalytics.track(.blazeCampaignListOpened, properties: analyticsProperties(for: source))
    }

    // MARK: - Campaign details

    static func trackCampaignDetailsOpened(for source: BlazeSource) {
        WPAnalytics.track(.blazeCampaignDetailsOpened, properties: analyticsProperties(for: source))
    }

    static func trackCampaignDetailsError(for source: BlazeSource) {
        WPAnalytics.track(.blazeCampaignDetailsError, properties: analyticsProperties(for: source))
    }

    static func trackCampaignDetailsDismissed(for source: BlazeSource) {
        WPAnalytics.track(.blazeCampaignDetailsDismissed, properties: analyticsProperties(for: source))
    }

    // MARK: - Helpers

    private static func analyticsProperties(for source: BlazeSource) -> [String: String] {
        return [WPAppAnalyticsKeySource: source.description]
    }

    private static func analyticsProperties(for source: BlazeSource, currentStep: String) -> [String: String] {
        return [
            WPAppAnalyticsKeySource: source.description,
            Self.currentStepPropertyKey: currentStep]
    }
}
