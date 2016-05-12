import Foundation

typealias PricedPlan = (plan: Plan, price: String)
typealias SitePricedPlans = (siteID: Int, activePlan: Plan, availablePlans: [PricedPlan])

typealias PlanID = Int

/// Represents a WordPress.com free or paid plan.
/// - seealso: [WordPress.com Store](https://store.wordpress.com/plans/)
struct Plan {
    let id: PlanID
    let title: String
    let fullTitle: String
    let tagline: String
    let iconUrl: NSURL
    let activeIconUrl: NSURL
    let productIdentifier: String?
    let featureGroups: [PlanFeatureGroupPlaceholder]
}

extension Plan {
    var isFreePlan: Bool {
        return productIdentifier == nil
    }
    var isPaidPlan: Bool {
        return !isFreePlan
    }
}

extension Plan: Equatable {}
func == (lhs: Plan, rhs: Plan) -> Bool {
    return lhs.id == rhs.id
}

extension Plan: Hashable {
    var hashValue: Int {
        return id.hashValue
    }
}

extension Plan: Comparable {}

func < (lhs: Plan, rhs: Plan) -> Bool {
    return lhs.id < rhs.id
}

protocol Identifiable {
    var id: Int { get }
}
extension Plan: Identifiable {}

extension Array where Element: Identifiable {
    func withID(searchID: Int) -> Element? {
        return filter({ $0.id == searchID }).first
    }
}

struct PlanFeature {
    let slug: String
    let title: String
    let description: String
    let iconURL: NSURL
}

struct PlanFeatureGroupPlaceholder {
    let title: String?
    let slugs: [String]
}

struct PlanFeatureGroup {
    let title: String?
    let features: [PlanFeature]
}
