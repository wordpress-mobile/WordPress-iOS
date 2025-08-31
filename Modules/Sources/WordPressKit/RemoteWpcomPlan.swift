import Foundation

public struct RemoteWpcomPlan {
    // A commma separated list of groups to which the plan belongs.
    public let groups: String
    // A comma separated list of plan_ids described by the plan description, e.g. 1 year and 2 year plans.
    public let products: String
    // The full name of the plan.
    public let name: String
    // The shortened name of the plan.
    public let shortname: String
    // The plan's tagline.
    public let tagline: String
    // A description of the plan.
    public let description: String
    // A comma separated list of slugs for the plan's features.
    public let features: String
    // An icon representing the plan.
    public let icon: String
    // The plan priority in Zendesk
    public let supportPriority: Int
    // The name of the plan in Zendesk
    public let supportName: String
    // Non localized version of the shortened name
    public let nonLocalizedShortname: String
}

public struct RemotePlanGroup {
    // A text slug identifying the group.
    public let slug: String
    // The name of the group.
    public let name: String
}

public struct RemotePlanFeature {
    // A text slug identifying the plan feature.
    public let slug: String
    // The name/title of the feature.
    public let title: String
    // A description of the feature.
    public let description: String
    // Deprecated.  An icon associeated with the feature.
    public let iconURL: URL?
}

public struct RemotePlanSimpleDescription {
    public let planID: Int
    public let name: String
}
