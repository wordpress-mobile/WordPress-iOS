import Foundation
import WordPressShared

struct PlanDetailViewModel {
    let plan: Plan
    let siteID: Int
    let activePlan: Plan

    /// Plan price. Empty string for a free plan
    let price: String

    let features: FeaturesViewModel

    enum FeaturesViewModel {
        case loading
        case error(String)
        case ready([PlanFeatureGroup])
    }

    func withFeatures(_ features: FeaturesViewModel) -> PlanDetailViewModel {
        return PlanDetailViewModel(
            plan: plan,
            siteID: siteID,
            activePlan: activePlan,
            price: price,
            features: features
        )
    }

    var tableViewModel: ImmuTable {
        switch features {
        case .loading, .error:
            return ImmuTable.Empty
        case .ready(let groups):
            return ImmuTable(sections: groups.map { group in
                let rows: [ImmuTableRow] = group.features.map({ feature in
                    return FeatureItemRow(title: feature.title, description: feature.description, iconURL: feature.iconURL)
                })
                return ImmuTableSection(headerText: group.title, rows: rows, footerText: nil)
                })
        }
    }

    var noResultsViewModel: NoResultsViewController.Model? {
        switch features {
        case .loading:
            return NoResultsViewController.Model(title: LocalizedText.loadingTitle)
        case .ready:
            return nil
        case .error:
            if let appDelegate = WordPressAppDelegate.sharedInstance(),
                appDelegate.connectionAvailable {
                return NoResultsViewController.Model(title: LocalizedText.errorTitle,
                                                     subtitle: LocalizedText.errorSubtitle,
                                                     buttonText: LocalizedText.errorButtonText)
            } else {
                return NoResultsViewController.Model(title: LocalizedText.noConnectionTitle,
                                                     subtitle: LocalizedText.noConnectionSubtitle)
            }
        }
    }

    var isActivePlan: Bool {
        return activePlan == plan
    }

    var priceText: String? {
        if price.isEmpty {
            return nil
        } else {
            return String(format: LocalizedText.price, price)
        }
    }

    var purchaseButtonVisible: Bool {
        return purchaseAvailability == .available
            || purchaseAvailability == .pending
    }

    var purchaseButtonSelected: Bool {
        return purchaseAvailability == .pending
    }

    fileprivate var purchaseAvailability: PurchaseAvailability {
        return StoreKitCoordinator.instance.purchaseAvailability(forPlan: plan, siteID: siteID, activePlan: activePlan)
    }

    private struct LocalizedText {
        static let loadingTitle = NSLocalizedString("Loading Plan...", comment: "Text displayed while loading plans details")
        static let errorTitle = NSLocalizedString("Oops", comment: "An informal exclaimation that means `something went wrong`.")
        static let errorSubtitle = NSLocalizedString("There was an error loading the plan", comment: "Text displayed when there is a failure loading the plan details")
        static let errorButtonText = NSLocalizedString("Contact support", comment: "Button label for contacting support")
        static let noConnectionTitle = NSLocalizedString("No connection", comment: "An error message title shown when there is no internet connection.")
        static let noConnectionSubtitle = NSLocalizedString("An active internet connection is required to view plans", comment: "An error message shown when there is no internet connection.")
        static let price = NSLocalizedString("%@ per year", comment: "Plan yearly price")
    }

}
