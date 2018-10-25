import UIKit

public class SiteStatsViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var insightsContainerView: UIView!
    @IBOutlet weak var statsContainerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!

    // MARK: - View

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupFilterBar()
        getSelectedPeriodFromUserDefaults()
    }

}

// MARK: - Private Extension

private extension SiteStatsViewController {

    struct Constants {
        static let userDefaultsKey = "LastSelectedStatsPeriodType"
    }

    enum StatsPeriodType: Int {
        case insights = 0
        case days = 1
        case weeks = 2
        case months = 3
        case years = 4

        static let allPeriods = [StatsPeriodType.insights, .days, .weeks, .months, .years]

        var filterTitle: String {
            switch self {
            case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
            case .days: return NSLocalizedString("Days", comment: "Title of Days stats filter.")
            case .weeks: return NSLocalizedString("Weeks", comment: "Title of Weeks stats filter.")
            case .months: return NSLocalizedString("Months", comment: "Title of Months stats filter.")
            case .years: return NSLocalizedString("Years", comment: "Title of Years stats filter.")
            }
        }
    }

    var currentSelectedPeriod: StatsPeriodType {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? StatsPeriodType.insights.rawValue
            return StatsPeriodType(rawValue: selectedIndex) ?? .insights
        }
        set {
            filterTabBar?.setSelectedIndex(newValue.rawValue)
            setContainerViewVisibility()
            saveSelectedPeriodToUserDefaults()
        }
    }

    func setContainerViewVisibility() {
        statsContainerView.isHidden = currentSelectedPeriod == .insights
        insightsContainerView.isHidden = !statsContainerView.isHidden
    }

}


// MARK: - FilterTabBar Support

private extension SiteStatsViewController {

    func setupFilterBar() {
        filterTabBar.tintColor = WPStyleGuide.wordPressBlue()
        filterTabBar.deselectedTabColor = WPStyleGuide.greyDarken10()
        filterTabBar.dividerColor = WPStyleGuide.greyLighten20()

        filterTabBar.items = StatsPeriodType.allPeriods.map { $0.filterTitle }
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        currentSelectedPeriod = StatsPeriodType(rawValue: filterBar.selectedIndex) ?? StatsPeriodType.insights

        // TODO: reload view based on selected tab
    }

}

// MARK: - User Defaults Support

private extension SiteStatsViewController {

    func saveSelectedPeriodToUserDefaults() {
        UserDefaults.standard.set(currentSelectedPeriod.rawValue, forKey: Constants.userDefaultsKey)
    }

    func getSelectedPeriodFromUserDefaults() {
        currentSelectedPeriod = StatsPeriodType(rawValue: UserDefaults.standard.integer(forKey: Constants.userDefaultsKey)) ?? .insights
    }
}
