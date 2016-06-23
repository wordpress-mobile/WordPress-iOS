@testable import WordPress

enum TestPlans {
    case free
    case premium
    case business

    var plan: Plan {
        switch self {
        case .free:
            return Plan(
                id: 1,
                title: NSLocalizedString("Free", comment: "Free plan name. As in https://store.wordpress.com/plans/"),
                fullTitle: NSLocalizedString("WordPress.com Free", comment: "Free plan name. As in https://store.wordpress.com/plans/"),
                tagline: NSLocalizedString("Anyone creating a simple blog or site.", comment: "Description of the Free plan"),
                iconUrl: NSURL(string: "http://s0.wordpress.com/i/store/plan-free.png")!,
                activeIconUrl: NSURL(string: "http://s0.wordpress.com/i/store/plan-free-active.png")!,
                productIdentifier: nil,
                featureGroups: []
            )
        case .premium:
            return Plan(
                id: 1003,
                title: NSLocalizedString("Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/"),
                fullTitle: NSLocalizedString("WordPress.com Premium", comment: "Premium paid plan name. As in https://store.wordpress.com/plans/"),
                tagline: NSLocalizedString("Serious bloggers and creatives.", comment: "Description of the Premium plan"),
                iconUrl: NSURL(string: "http://s0.wordpress.com/i/store/plan-premium.png")!,
                activeIconUrl: NSURL(string: "http://s0.wordpress.com/i/store/plan-premium-active.png")!,
                productIdentifier: "com.wordpress.test.premium.subscription.1year",
                featureGroups: []
            )
        case .business:
            return Plan(
                id: 1008,
                title: NSLocalizedString("Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/"),
                fullTitle: NSLocalizedString("WordPress.com Business", comment: "Business paid plan name. As in https://store.wordpress.com/plans/"),
                tagline: NSLocalizedString("Business websites and ecommerce.", comment: "Description of the Business plan"),
                iconUrl: NSURL(string: "http://s0.wordpress.com/i/store/plan-business.png")!,
                activeIconUrl: NSURL(string: "http://s0.wordpress.com/i/store/plan-business-active.png")!,
                productIdentifier: "com.wordpress.test.business.subscription.1year",
                featureGroups: []
            )
        }
    }

    var product: MockProduct {
        return MockProduct(localizedDescription: plan.tagline,
                           localizedTitle: plan.title,
                           price: 299.99,
                           priceLocale: NSLocale(localeIdentifier: "en-US"),
                           productIdentifier: plan.productIdentifier ?? "")
    }

    private static let allTestPlans = [ TestPlans.free, TestPlans.premium, TestPlans.business ]

    static let allPlans = allTestPlans.map({ $0.plan })
    static let allProducts = allTestPlans.map({ $0.product })
}
