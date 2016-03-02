import Foundation

typealias Plan = PlanEnum

/// Represents a WordPress.com free or paid plan.
/// - seealso: [WordPress.com Store](https://store.wordpress.com/plans/)
@objc
enum PlanEnum: Int {
    // Product IDs of the various plans (https://public-api.wordpress.com/rest/v1/plans/)
    case Free = 1
    case Premium = 1003
    case Business = 1008
    
    var slug: String {
        switch self {
        case .Free:
            return "free"
        case .Premium:
            return "premium"
        case .Business:
            return "business"
        }
    }

    /// The StoreKit product identifier, or nil for free plans
    var productIdentifier: String? {
        switch self {
        case .Free:
            return nil
        case .Premium:
            return "com.wordpress.test.premium.subscription.1year"
        case .Business:
            return "com.wordpress.test.business.subscription.1year"
        }
    }
    
    /// The localized name of the plan (e.g. "Business").
    var title: String {
        switch self {
        case .Free:
            return NSLocalizedString("Free", comment: "Free plan name. As in https://store.wordpress.com/plans/")
        case .Premium:
            return NSLocalizedString("Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/")
        case .Business:
            return NSLocalizedString("Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/")
        }
    }

    /// The localized long name of the plan (e.g. "WordPress.com Business").
    var fullTitle: String {
        switch self {
        case .Free:
            return NSLocalizedString("WordPress.com Free", comment: "Free plan name. As in https://store.wordpress.com/plans/")
        case .Premium:
            return NSLocalizedString("WordPress.com Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/")
        case .Business:
            return NSLocalizedString("WordPress.com Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/")
        }
    }

    /// A description of the plan, explains who is the plan's target audience
    var description: String {
        switch self {
        case .Free:
            return NSLocalizedString("Anyone creating a simple blog or site.", comment: "Description of the Free plan")
        case .Premium:
            return NSLocalizedString("Serious bloggers and creatives.", comment: "Description of the Premium plan")
        case .Business:
            return NSLocalizedString("Business websites and ecommerce.", comment: "Description of the Business plan")
        }
    }
    
    /// An array of the features that this plan offers (e.g. No Ads, Premium Themes)
    var features: [PlanFeature] {
        switch self {
        case .Free:
            return [
                .WordPressSite,
                .FullAccess,
                .StorageSpace(NSLocalizedString("3GB", comment: "3 gigabytes of storage")),
                .Support(NSLocalizedString("Community", comment: "Noun. Customer support from the community (forums)."))
            ]
        case .Premium:
            return [
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
        case .Business:
            return [
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
        }
    }
}

// We currently need to access the title of a plan in BlogDetailsViewController, which is
// written in Objective-C. This small wrapper lets us do that.
@objc(Plan)
class PlanObjc: NSObject {
    @nonobjc
    private let plan: Plan

    init?(planID: Int) {
        guard let plan = Plan(rawValue: planID) else {
            // We need to initialize this to something before we can fail
            // Should be fixed in Swift 2.2
            self.plan = .Free
            super.init()
            return nil
        }

        self.plan = plan
        super.init()
    }
    
    var title: String {
        return plan.title
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

// Blog extension
extension Blog {
    /// The blog's active plan, if any.
    /// - note: If the stored planID doesn't match a known plan, it returns `nil`
    var plan: Plan? {
        // FIXME: Remove cast if/when we merge https://github.com/wordpress-mobile/WordPress-iOS/pull/4762
        // @koke 2016-02-03
        guard let planID = planID as Int? else {
            return nil
        }
        return Plan(rawValue: planID)
    }
}
