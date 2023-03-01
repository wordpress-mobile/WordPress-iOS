import Foundation

@objcMembers class BlazeEventsTracker: NSObject {

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

    private static func analyticsProperties(for source: BlazeSource) -> [String: String] {
        return [WPAppAnalyticsKeySource: source.description]
    }
}
