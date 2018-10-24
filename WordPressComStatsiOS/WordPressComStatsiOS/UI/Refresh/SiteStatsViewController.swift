import UIKit

public class SiteStatsViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var insightsContainerView: UIView!
    @IBOutlet weak var statsContainerView: UIView!

    // MARK: - View

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupFilterBar()
    }

}

// MARK: - Private Extension

private extension SiteStatsViewController {

    func setupFilterBar() {
        filterTabBar.tintColor = WPStyleGuide.wordPressBlue()
        filterTabBar.deselectedTabColor = WPStyleGuide.greyDarken10()
        filterTabBar.dividerColor = WPStyleGuide.greyLighten20()

        filterTabBar.items = Filter.allFilters.map { $0.title }
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    var filter: Filter {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? Filter.insights.rawValue
            return Filter(rawValue: selectedIndex) ?? .insights
        }
        set {
            filterTabBar?.setSelectedIndex(newValue.rawValue)
            // TODO: reload view based on selected tab
        }
    }

    enum Filter: Int {
        case insights = 0
        case daily = 1
        case weekly = 2
        case monthly = 3
        case yearly = 4

        static let allFilters = [Filter.insights, .daily, .weekly, .monthly, .yearly]

        var title: String {
            switch self {
            case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
            case .daily: return NSLocalizedString("Days", comment: "Title of Days stats filter.")
            case .weekly: return NSLocalizedString("Weeks", comment: "Title of Weeks stats filter.")
            case .monthly: return NSLocalizedString("Months", comment: "Title of Months stats filter.")
            case .yearly: return NSLocalizedString("Years", comment: "Title of Years stats filter.")
            }
        }
    }

}

// MARK: - FilterTabBar Methods

extension SiteStatsViewController {

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        // TODO: reload view based on selected tab
        print("🔴 selectedFilterDidChange. selected filter: ", filterBar.selectedIndex, filter.title)
    }
}
