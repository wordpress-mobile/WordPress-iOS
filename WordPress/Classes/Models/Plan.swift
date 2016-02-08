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
