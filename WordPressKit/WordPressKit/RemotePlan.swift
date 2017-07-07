import Foundation

public typealias PricedPlan = (plan: RemotePlan, price: String)
public typealias SitePricedPlans = (siteID: Int, activePlan: RemotePlan, availablePlans: [PricedPlan])
public typealias RemotePlanFeatures = [PlanID: [RemotePlanFeature]]

public typealias PlanID = Int

/// Represents a WordPress.com free or paid plan.
/// - seealso: [WordPress.com Store](https://store.wordpress.com/plans/)
public struct RemotePlan {
    public let id: PlanID
    public let title: String
    public let fullTitle: String
    public let tagline: String
    public let iconUrl: URL
    public let activeIconUrl: URL
    public let productIdentifier: String?
    public let featureGroups: [RemotePlanFeatureGroupPlaceholder]
    
    public init(id: PlanID, title: String, fullTitle: String, tagline: String,
                iconUrl: URL, activeIconUrl: URL, productIdentifier: String?,
                featureGroups: [RemotePlanFeatureGroupPlaceholder]) {
        self.id = id
        self.title = title
        self.fullTitle = fullTitle
        self.tagline = tagline
        self.iconUrl = iconUrl
        self.activeIconUrl = activeIconUrl
        self.productIdentifier = productIdentifier
        self.featureGroups = featureGroups
    }
}

extension RemotePlan {
    public var isFreePlan: Bool {
        return productIdentifier == nil
    }
    public var isPaidPlan: Bool {
        return !isFreePlan
    }
}

extension RemotePlan: Equatable {}
public func == (lhs: RemotePlan, rhs: RemotePlan) -> Bool {
    return lhs.id == rhs.id
}

extension RemotePlan: Hashable {
    public var hashValue: Int {
        return id.hashValue
    }
}

extension RemotePlan: Comparable {}

public func < (lhs: RemotePlan, rhs: RemotePlan) -> Bool {
    return lhs.id < rhs.id
}

protocol Identifiable {
    var id: Int { get }
}
extension RemotePlan: Identifiable {}

extension Array where Element: Identifiable {
    func withID(_ searchID: Int) -> Element? {
        return filter({ $0.id == searchID }).first
    }
}

public struct RemotePlanFeature {
    public let slug: String
    public let title: String
    public let description: String
    public let iconURL: URL?
}

public struct RemotePlanFeatureGroupPlaceholder {
    public let title: String?
    public let slugs: [String]
}

public struct RemotePlanFeatureGroup {
    public var title: String?
    public var features: [RemotePlanFeature]
    
    public init(title: String?, features: [RemotePlanFeature]) {
        self.title = title;
        self.features = features;
    }
}
