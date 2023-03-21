import Foundation

struct MovedToJetpackEventsTracker {

    let source: MovedToJetpackSource

    func trackScreenDisplayed() {
        WPAnalytics.track(.removeStaticPosterDisplayed, properties: analyticsProperties(for: source))
    }

    func trackJetpackButtonTapped() {
        WPAnalytics.track(.removeStaticPosterButtonTapped, properties: analyticsProperties(for: source))
    }

    func trackJetpackLinkTapped() {
        WPAnalytics.track(.removeStaticPosterLinkTapped, properties: analyticsProperties(for: source))
    }

    private func analyticsProperties(for source: MovedToJetpackSource) -> [String: String] {
        return [WPAppAnalyticsKeySource: source.description]
    }
}
