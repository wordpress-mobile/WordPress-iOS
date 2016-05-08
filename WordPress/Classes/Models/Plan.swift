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

// Obj-C bridge functions
final class PlansBridge: NSObject {
    static func titleForPlan(withID planID: PlanID) -> String? {
        return defaultPlans
            .withID(planID)?
            .title
    }
}


// FIXME: not too happy with the global constant, but hardcoded plans are going away soon
let defaultPlans: [Plan] = [
    Plan(
        id: 1,
        title: NSLocalizedString("Free", comment: "Free plan name. As in https://store.wordpress.com/plans/"),
        fullTitle: NSLocalizedString("WordPress.com Free", comment: "Free plan name. As in https://store.wordpress.com/plans/"),
        tagline: NSLocalizedString("Anyone creating a simple blog or site.", comment: "Description of the Free plan"),
        productIdentifier: nil,
        featureGroups: []
    ),
    Plan(
        id: 1003,
        title: NSLocalizedString("Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/"),
        fullTitle: NSLocalizedString("WordPress.com Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/"),
        tagline: NSLocalizedString("Serious bloggers and creatives.", comment: "Description of the Premium plan"),
        productIdentifier: "com.wordpress.test.premium.subscription.1year",
        featureGroups: []
    ),
    Plan(
        id: 1008,
        title: NSLocalizedString("Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/"),
        fullTitle: NSLocalizedString("WordPress.com Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/"),
        tagline: NSLocalizedString("Business websites and ecommerce.", comment: "Description of the Business plan"),
        productIdentifier: "com.wordpress.test.business.subscription.1year",
        featureGroups: []
    ),
]

protocol Identifiable {
    var id: Int { get }
}
extension Plan: Identifiable {}

extension Array where Element: Identifiable {
    func withID(searchID: Int) -> Element? {
        return filter({ $0.id == searchID }).first
    }
}

// Icons
extension Plan {
    // Temporary hardcoded map
    // We need to store plan image URLs and use those
    // https://github.com/wordpress-mobile/WordPress-iOS/issues/5099
    var slug: String {
        switch id {
        case 1:
            return "free"
        case 1003:
            return "premium"
        case 1008:
            return "business"
        default:
            return ""
        }
    }
    /// The name of the image that represents the plan when it's not the current plan
    var imageName: String {
        return "plan-\(slug)"
    }

    /// The name of the image that represents the plan when it's the current plan
    var activeImageName: String {
        return "plan-\(slug)-active"
    }

    /// An image that represents the plan when it's not the current plan
    var image: UIImage {
        return UIImage(named: imageName)!
    }

    /// An image that represents the plan when it's the current plan
    var activeImage: UIImage {
        return UIImage(named: activeImageName)!
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
