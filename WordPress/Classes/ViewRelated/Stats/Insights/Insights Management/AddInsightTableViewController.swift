import UIKit
import Gridicons

// This exists in addition to `SiteStatsInsightsDelegate` because `[StatSection]`
// can't be represented in an Obj-C protocol.
protocol StatsInsightsManagementDelegate: AnyObject {
    func userUpdatedActiveInsights(_ insights: [StatSection])
    func insightsManagementDismissed()
}

class AddInsightTableViewController: UITableViewController {

    // MARK: - Properties
    private weak var insightsManagementDelegate: StatsInsightsManagementDelegate?
    private weak var insightsDelegate: SiteStatsInsightsDelegate?

    /// Stored so that we can check if the user has made any changes.
    private var originalInsightsShown = [StatSection]()
    private var insightsShown = [StatSection]() {
        didSet {
            updateSaveButton()
        }
    }

    private var selectedStat: StatSection?

    private lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveInsights))

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Init

    override init(style: UITableView.Style) {
        super.init(style: style)

        navigationItem.title = TextContent.title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(insightsDelegate: SiteStatsInsightsDelegate, insightsManagementDelegate: StatsInsightsManagementDelegate? = nil, insightsShown: [StatSection]) {
        self.init(style: .grouped)
        self.insightsDelegate = insightsDelegate
        self.insightsManagementDelegate = insightsManagementDelegate
        self.insightsShown = insightsShown
        self.originalInsightsShown = insightsShown
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([AddInsightStatRow.self], tableView: tableView)
        reloadViewModel()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        tableView.accessibilityIdentifier = TextContent.title

        if FeatureFlag.statsNewAppearance.enabled {
            tableView.isEditing = true
            tableView.allowsSelectionDuringEditing = true
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .gridicon(.cross), style: .plain, target: self, action: #selector(doneTapped))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if FeatureFlag.statsNewAppearance.enabled {
            // TODO: Check for any changes, prompt user
        } else {
            if selectedStat == nil {
                insightsDelegate?.addInsightDismissed?()
            }
        }
    }

    // MARK: TableView Data Source / Delegate Overrides

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 38
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard FeatureFlag.statsNewAppearance.enabled else {
            return false
        }

        return isActiveCardsSection(indexPath.section)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard FeatureFlag.statsNewAppearance.enabled else {
            return
        }

        if isActiveCardsSection(sourceIndexPath.section) && isActiveCardsSection(destinationIndexPath.section) {
            let item = insightsShown.remove(at: sourceIndexPath.row)
            insightsShown.insert(item, at: destinationIndexPath.row)
            reloadViewModel()
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard FeatureFlag.statsNewAppearance.enabled else {
            return false
        }

        return insightsShown.count > 0 && isActiveCardsSection(indexPath.section)
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if isActiveCardsSection(proposedDestinationIndexPath.section) {
            return proposedDestinationIndexPath
        }

        return IndexPath(row: insightsShown.count - 1, section: 0)
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    private func isActiveCardsSection(_ sectionIndex: Int) -> Bool {
        return sectionIndex == 0
    }

    // MARK: - Actions

    private func updateSaveButton() {
        guard FeatureFlag.statsNewAppearance.enabled else {
            return
        }

        if insightsShown != originalInsightsShown {
            navigationItem.rightBarButtonItem = saveButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc func saveInsights() {
        insightsManagementDelegate?.userUpdatedActiveInsights(insightsShown)

        dismiss(animated: true, completion: nil)
    }

    @objc private func doneTapped() {
        WPAnalytics.trackEvent(.statsInsightsManagementDismissed)
        dismiss(animated: true, completion: nil)

        // TODO: Prompt user if they have unsaved changes
    }

    fileprivate enum TextContent {
        static let title = NSLocalizedString("stats.insights.management.title", value: "Manage Stats Cards", comment: "Title of the Stats Insights Management screen")
        static let activeCardsHeader = NSLocalizedString("stats.insights.management.activeCards", value: "Active Cards", comment: "Header title indicating which Stats Insights cards the user currently has set to active.")
        static let placeholderRowTitle = NSLocalizedString("stats.insights.management.selectCardsPrompt", value: "Select cards from the list below", comment: "Prompt displayed on the Stats Insights management screen telling the user to tap a row to add it to their list of active cards.")
    }
}

private extension AddInsightTableViewController {

    // MARK: - Table Model

    func reloadViewModel() {
        tableHandler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        return ImmuTable(sections: [ selectedStatsSection(),
                                     sectionForCategory(.general),
                                     sectionForCategory(.postsAndPages),
                                     sectionForCategory(.activity) ].compactMap({$0})
        )
    }

    // MARK: - Table Sections

    func selectedStatsSection() -> ImmuTableSection? {
        guard FeatureFlag.statsNewAppearance.enabled else {
            return nil
        }

        guard insightsShown.count > 0 else {
            return ImmuTableSection(headerText: TextContent.activeCardsHeader, rows: [placeholderRow])
        }

        return ImmuTableSection(headerText: TextContent.activeCardsHeader,
                                rows: insightsShown.map {
                                    return AddInsightStatRow(title: $0.insightManagementTitle,
                                                             enabled: true,
                                                             action: rowActionFor($0)) }
        )
    }

    func sectionForCategory(_ category: InsightsCategories) -> ImmuTableSection? {
        guard FeatureFlag.statsNewAppearance.enabled else {
            return ImmuTableSection(headerText: category.title,
                                    rows: category.insights.map {
                                        let enabled = !insightsShown.contains($0)
                                        return AddInsightStatRow(title: $0.insightManagementTitle,
                                                                 enabled: enabled,
                                                                 action: enabled ? rowActionFor($0) : nil) }
            )
        }

        let rows = category.insights.filter({ !self.insightsShown.contains($0) })
        guard rows.count > 0 else {
            return nil
        }

        return ImmuTableSection(headerText: category.title,
                                rows: rows.map {
                                    return AddInsightStatRow(title: $0.insightManagementTitle,
                                                             enabled: false,
                                                             action: rowActionFor($0)) }
        )
    }

    func rowActionFor(_ statSection: StatSection) -> ImmuTableAction {
        return { [unowned self] row in
            if FeatureFlag.statsNewAppearance.enabled {
                toggleRow(for: statSection)
            } else {
                self.selectedStat = statSection
                self.insightsDelegate?.addInsightSelected?(statSection)

                WPAnalytics.track(.statsInsightsManagementSaved, properties: ["types": [statSection.title]])
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func toggleRow(for statSection: StatSection) {
        if let index = insightsShown.firstIndex(of: statSection) {
            insightsShown.remove(at: index)
        } else {
            insightsShown.append(statSection)
        }

        reloadViewModel()
    }

    var placeholderRow: ImmuTableRow {
        return AddInsightStatRow(title: TextContent.placeholderRowTitle,
                                 enabled: false,
                                 action: nil)
    }

    // MARK: - Insights Categories

    enum InsightsCategories {
        case general
        case postsAndPages
        case activity

        var title: String {
            switch self {
            case .general:
                return NSLocalizedString("General", comment: "Add New Stats Card category title")
            case .postsAndPages:
                return NSLocalizedString("Posts and Pages", comment: "Add New Stats Card category title")
            case .activity:
                return NSLocalizedString("Activity", comment: "Add New Stats Card category title")
            }
        }

        var insights: [StatSection] {
            switch self {
            case .general:
                if FeatureFlag.statsNewInsights.enabled {
                    return [.insightsViewsVisitors, .insightsAllTime, .insightsMostPopularTime, .insightsAnnualSiteStats, .insightsTodaysStats]
                }
                return [.insightsAllTime, .insightsMostPopularTime, .insightsAnnualSiteStats, .insightsTodaysStats]

            case .postsAndPages:
                return [.insightsLatestPostSummary, .insightsPostingActivity, .insightsTagsAndCategories]
            case .activity:
                return [.insightsCommentsPosts, .insightsFollowersEmail, .insightsFollowerTotals, .insightsPublicize]
            }
        }
    }

}
