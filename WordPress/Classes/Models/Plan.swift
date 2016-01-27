import Foundation

/// Represents a WordPress.com free or paid plan.
/// - seealso: [WordPress.com Store](https://store.wordpress.com/plans/)
enum Plan: String {
    case Free = "free"
    case Premium = "premium"
    case Business = "business"

    /// The localized name of the plan
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

// Icons
extension Plan {
    /// The name of the image that represents the plan when it's not the current plan
    var imageName: String {
        return "plan-\(rawValue)"
    }

    /// The name of the image that represents the plan when it's the current plan
    var activeImageName: String {
        return "plan-\(rawValue)-active"
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
