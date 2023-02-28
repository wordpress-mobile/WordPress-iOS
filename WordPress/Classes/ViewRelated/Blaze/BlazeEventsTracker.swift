import Foundation

@objcMembers class BlazeEventsTracker: NSObject {

    private static let currentStepPropertyKey = "current_step"

    static func trackBlazeFeatureDisplayed(for source: BlazeSource) {
        WPAnalytics.track(.blazeFeatureDisplayed, properties: analyticsProperties(for: source))
    }

    static func trackBlazeFeatureTapped(for source: BlazeSource) {
        WPAnalytics.track(.blazeFeatureTapped, properties: analyticsProperties(for: source))
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

    static func trackBlazeFlowError(for source: BlazeSource, currentStep: String) {
        WPAnalytics.track(.blazeFlowError, properties: analyticsProperties(for: source, currentStep: currentStep))
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
