import Foundation

/// Represents a WordPress.com free or paid plan.
/// - seealso: [WordPress.com Store](https://store.wordpress.com/plans/)
enum Plan: String {
    case Free = "free"
    case Premium = "premium"
    case Business = "business"
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
