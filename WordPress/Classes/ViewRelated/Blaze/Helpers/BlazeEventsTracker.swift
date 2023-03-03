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

    static func trackContextualMenuAccessed(for source: BlazeSource) {
        WPAnalytics.track(.blazeContextualMenuAccessed, properties: analyticsProperties(for: source))
    }

    static func trackHideThisTapped(for source: BlazeSource) {
        WPAnalytics.track(.blazeCardHidden, properties: analyticsProperties(for: source))
    }

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

    private static func analyticsProperties(for source: BlazeSource) -> [String: String] {
        return [WPAppAnalyticsKeySource: source.description]
    }

    private static func analyticsProperties(for source: BlazeSource, currentStep: String) -> [String: String] {
        return [
            WPAppAnalyticsKeySource: source.description,
            Self.currentStepPropertyKey: currentStep]
    }
}
