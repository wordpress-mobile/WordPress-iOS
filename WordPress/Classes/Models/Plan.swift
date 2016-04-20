import Foundation

typealias PricedPlan = (plan: Plan, price: String)
typealias SitePricedPlans = (activePlan: Plan, availablePlans: [PricedPlan])

/// Represents a WordPress.com free or paid plan.
/// - seealso: [WordPress.com Store](https://store.wordpress.com/plans/)
struct Plan {
    let id: Int
    let slug: String
    let title: String
    let fullTitle: String
    let description: String
    let productIdentifier: String?
    let features: [PlanFeature]
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

extension Plan: Comparable {}

func < (lhs: Plan, rhs: Plan) -> Bool {
    return lhs.id < rhs.id
}

// Obj-C bridge functions
final class PlansBridge: NSObject {
    static func titleForPlan(withID planID: Int) -> String? {
        return defaultPlans
            .withID(planID)?
            .title
    }
}


// FIXME: not too happy with the global constant, but hardcoded plans are going away soon
let defaultPlans: [Plan] = [
    Plan(
        id: 1,
        slug: "free",
        title: NSLocalizedString("Free", comment: "Free plan name. As in https://store.wordpress.com/plans/"),
        fullTitle: NSLocalizedString("WordPress.com Free", comment: "Free plan name. As in https://store.wordpress.com/plans/"),
        description: NSLocalizedString("Anyone creating a simple blog or site.", comment: "Description of the Free plan"),
        productIdentifier: nil,
        features: [
            .WordPressSite,
            .FullAccess,
            .StorageSpace(NSLocalizedString("3GB", comment: "3 gigabytes of storage")),
            .Support(NSLocalizedString("Community", comment: "Noun. Customer support from the community (forums)."))
        ]
    ),
    Plan(
        id: 1003,
        slug: "premium",
        title: NSLocalizedString("Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/"),
        fullTitle: NSLocalizedString("WordPress.com Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/"),
        description: NSLocalizedString("Serious bloggers and creatives.", comment: "Description of the Premium plan"),
        productIdentifier: "com.wordpress.test.premium.subscription.1year",
        features: [
            .WordPressSite,
            .FullAccess,
            .CustomDomain,
            .NoAds,
            .CustomFontsAndColors,
            .CSSEditing,
            .VideoPress,
            .StorageSpace(NSLocalizedString("13GB", comment: "13 gigabytes of storage")),
            .Support(NSLocalizedString("In-App & Direct Email", comment: "Types of support available to a user."))
        ]
    ),
    Plan(
        id: 1008,
        slug: "business",
        title: NSLocalizedString("Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/"),
        fullTitle: NSLocalizedString("WordPress.com Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/"),
        description: NSLocalizedString("Business websites and ecommerce.", comment: "Description of the Business plan"),
        productIdentifier: "com.wordpress.test.business.subscription.1year",
        features: [
            .WordPressSite,
            .FullAccess,
            .CustomDomain,
            .NoAds,
            .CustomFontsAndColors,
            .CSSEditing,
            .VideoPress,
            .ECommerce,
            .PremiumThemes,
            .GoogleAnalytics,
            .StorageSpace(NSLocalizedString("Unlimited", comment: "Unlimited data storage")),
            .Support(NSLocalizedString("In-App & Live Chat", comment: "Types of support available to a user."))
        ]
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

enum PlanFeature: Equatable {
    static let allFeatures: [PlanFeature] = [ .WordPressSite, .FullAccess, .CustomDomain, .NoAds, .CustomFontsAndColors, .CSSEditing, .VideoPress, .ECommerce, .PremiumThemes, .GoogleAnalytics, .StorageSpace(""), .Support("") ]
    
    case WordPressSite
    case FullAccess
    case CustomDomain
    case NoAds
    case CustomFontsAndColors
    case CSSEditing
    case VideoPress
    case ECommerce
    case PremiumThemes
    case GoogleAnalytics
    case StorageSpace(String)
    case Support(String)
    
    var title: String {
        switch self {
        case WordPressSite:
            return NSLocalizedString("WordPress.com Site", comment: "The site that a user gets by signing up at WordPress.com. A feature provided by every plan.")
        case FullAccess:
            return NSLocalizedString("Full Access to Web Version", comment: "A WordPress.com feature that every user gets when they select a plan in the mobile app.")
        case CustomDomain:
            return NSLocalizedString("A Custom Site Address", comment: "A feature that users gain when purchasing a paid plan.")
        case NoAds:
            return NSLocalizedString("No Ads", comment: "A feature that users gain when purchasing a paid plan. No advertising will be displayed on their site.")
        case CustomFontsAndColors:
            return NSLocalizedString("Custom Fonts & Colors", comment: "A feature that users gain when purchasing a paid plan. They can set custom fonts and colors on their site.")
        case CSSEditing:
            return NSLocalizedString("CSS Editing", comment: "A feature that users gain when purchasing a paid plan. They can edit the CSS of their site.")
        case VideoPress:
            return NSLocalizedString("Video Storage & Hosting", comment: "A feature that users gain when purchasing a paid plan. They can upload and embed videos using VideoPress.")
        case ECommerce:
            return NSLocalizedString("eCommerce", comment: "A feature that users gain when purchasing a paid plan. They can embed a store in their site.")
        case PremiumThemes:
            return NSLocalizedString("Premium Themes", comment: "A feature that users gain when purchasing a paid plan. They have unlimited access to premium themes.")
        case GoogleAnalytics:
            return NSLocalizedString("Google Analytics", comment: "A feature that users gain when purchasing a paid plan. ")
        case StorageSpace:
            return NSLocalizedString("Storage Space", comment: "A feature that users gain when purchasing a paid plan. They get a certain level of storage space for uploads.")
        case Support:
            return NSLocalizedString("Support", comment: "A feature that users gain when purchasing a paid plan. Customer support such as live chat or email.")
        }
    }
    
    var webOnly: Bool {
        switch self {
        case .CustomDomain, .ECommerce, .GoogleAnalytics:
            return true
        default:
            return false
        }
    }
    
    var description: String? {
        switch self {
        case .StorageSpace(let space):
            return space
        case .Support(let type):
            return type
        default:
            return nil
        }
    }
}

func ==(lhs: PlanFeature, rhs: PlanFeature) -> Bool {
    return lhs.title == rhs.title
}
