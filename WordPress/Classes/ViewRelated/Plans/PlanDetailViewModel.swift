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

    var noResultsViewModel: WPNoResultsView.Model? {
        switch features {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plan...", comment: "Text displayed while loading plans details")
            )
        case .ready:
            return nil
        case .error:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Oops", comment: ""),
                message: NSLocalizedString("There was an error loading the plan", comment: ""),
                buttonTitle: NSLocalizedString("Contact support", comment: "")
            )
        }
    }

    var isActivePlan: Bool {
        return activePlan == plan
    }

    var priceText: String? {
        if price.isEmpty {
            return nil
        } else {
            return String(format: NSLocalizedString("%@ per year", comment: "Plan yearly price"), price)
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
}
