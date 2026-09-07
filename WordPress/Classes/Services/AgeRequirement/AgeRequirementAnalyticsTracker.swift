import WordPressShared

@MainActor
protocol AgeRequirementAnalyticsTracking {
    func track(_ outcome: AgeRequirementCheckOutcome, userState: AgeRequirementUserState)
}

@MainActor
struct AgeRequirementAnalyticsTracker: AgeRequirementAnalyticsTracking {
    private let tracker: AnalyticsEventTracking.Type

    init(tracker: AnalyticsEventTracking.Type = WPAnalytics.self) {
        self.tracker = tracker
    }

    func track(_ outcome: AgeRequirementCheckOutcome, userState: AgeRequirementUserState) {
        var properties: [String: String] = [
            "outcome": outcome.analyticsValue,
            "logged_out": String(outcome == .restricted),
            "wpcom_signed_in": String(userState.wpComSignedIn),
            "self_hosted_site_count": String(userState.selfHostedSiteCount)
        ]
        if case .notChecked(let reason) = outcome {
            properties["reason"] = reason.rawValue
        }
        tracker.track(AnalyticsEvent(name: "age_requirement_check", properties: properties))
    }
}

private extension AgeRequirementCheckOutcome {
    var analyticsValue: String {
        switch self {
        case .allowed: "allowed"
        case .restricted: "restricted"
        case .declined: "declined"
        case .unavailable: "unavailable"
        case .error: "error"
        case .notChecked: "not_checked"
        }
    }
}
