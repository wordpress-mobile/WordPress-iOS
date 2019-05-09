import Foundation
import WordPressShared

struct PlanDetailViewModel {
    let plan: Plan
    let features: FeaturesViewModel

    enum FeaturesViewModel {
        case loading
        case error(String)
        case ready([PlanFeature])
    }

    func withFeatures(_ features: FeaturesViewModel) -> PlanDetailViewModel {
        return PlanDetailViewModel(
            plan: plan,
            features: features
        )
    }

    var tableViewModel: ImmuTable {
        switch features {
        case .loading, .error:
            return ImmuTable.Empty
        case .ready(let features):
            let featureSlugs = plan.features.split(separator: ",")
            // Assume the order of the slugs is the order we want to display features.
            let planFeatures = featureSlugs.compactMap { slug -> PlanFeature? in
                return features.filter { feature -> Bool in
                    return feature.slug == slug
                }.first
            }

            let rows: [ImmuTableRow] = planFeatures.map({ feature in
                let row = FeatureItemRow(title: feature.title, description: feature.summary, iconURL: nil)
                return row
            })
            return ImmuTable(sections: [ImmuTableSection(headerText: "", rows: rows, footerText: nil)])
        }
    }

    var noResultsViewModel: NoResultsViewController.Model? {
        switch features {
        case .loading:
            return NoResultsViewController.Model(title: LocalizedText.loadingTitle)
        case .ready:
            return nil
        case .error:
            if let appDelegate = WordPressAppDelegate.shared,
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
