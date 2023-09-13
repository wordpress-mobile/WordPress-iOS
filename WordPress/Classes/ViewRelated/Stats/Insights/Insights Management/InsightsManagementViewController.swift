import UIKit
import Gridicons

// This exists in addition to `SiteStatsInsightsDelegate` because `[StatSection]`
// can't be represented in an Obj-C protocol.
protocol StatsInsightsManagementDelegate: AnyObject {
    func userUpdatedActiveInsights(_ insights: [StatSection])
}

class InsightsManagementViewController: UITableViewController {

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

    private var insightsInactive: [StatSection] {
        StatSection.allInsights
            .filter({ !self.insightsShown.contains($0) && !InsightsManagementViewController.insightsNotSupportedForManagement.contains($0) })
    }

    private var hasChanges: Bool {
        return insightsShown != originalInsightsShown
    }

    private var selectedStat: StatSection?

    private lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

    private lazy var tableHandler: ImmuTableViewHandler = {
        let handler = ImmuTableViewHandler(takeOver: self)
        handler.automaticallyReloadTableView = false
        return handler
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
        self.init(style: AppConfiguration.statsRevampV2Enabled ? .insetGrouped : .grouped)
        self.insightsDelegate = insightsDelegate
        self.insightsManagementDelegate = insightsManagementDelegate
        let insightsShownSupportedForManagement = insightsShown.filter { !InsightsManagementViewController.insightsNotSupportedForManagement.contains($0) }
        self.insightsShown = insightsShownSupportedForManagement
        self.originalInsightsShown = insightsShownSupportedForManagement
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([AddInsightStatRow.self], tableView: tableView)
        reloadViewModel()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        tableView.estimatedSectionHeaderHeight = 38
        tableView.accessibilityIdentifier = TextContent.title

        if AppConfiguration.statsRevampV2Enabled {
            tableView.isEditing = true
            tableView.allowsSelectionDuringEditing = true
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .gridicon(.cross), style: .plain, target: self, action: #selector(doneTapped))
    }

    func handleDismissViaGesture(from presenter: UIViewController) {
        if AppConfiguration.statsRevampV2Enabled && hasChanges {
            promptToSave(from: presenter)
        } else {
            trackDismiss()
        }
    }

    // MARK: TableView Data Source / Delegate Overrides

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard AppConfiguration.statsRevampV2Enabled else {
            return false
        }

        return isActiveCardsSection(indexPath.section)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard AppConfiguration.statsRevampV2Enabled else {
            return
        }

        if isActiveCardsSection(sourceIndexPath.section) && isActiveCardsSection(destinationIndexPath.section) {
            let item = insightsShown.remove(at: sourceIndexPath.row)
            insightsShown.insert(item, at: destinationIndexPath.row)
            reloadViewModel()
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard AppConfiguration.statsRevampV2Enabled else {
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
        guard AppConfiguration.statsRevampV2Enabled else {
            return
        }

        if hasChanges {
            navigationItem.rightBarButtonItem = saveButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc private func doneTapped() {
        if AppConfiguration.statsRevampV2Enabled && hasChanges {
            promptToSave(from: self)
        } else {
            dismiss()
        }
    }

    @objc func saveTapped() {
        saveChanges()

        dismiss(animated: true, completion: nil)
    }

    private func dismiss() {
        trackDismiss()

        dismiss(animated: true, completion: nil)
    }

    private func trackDismiss() {
        WPAnalytics.trackEvent(.statsInsightsManagementDismissed)
        insightsDelegate?.addInsightDismissed?()
    }

    private func saveChanges() {
        insightsManagementDelegate?.userUpdatedActiveInsights(insightsShown)

        WPAnalytics.track(.statsInsightsManagementSaved, properties: ["types": [insightsShown.map({$0.title})]])

        // Update original to stop us detecting changes on dismiss
        originalInsightsShown = insightsShown
    }

    private func promptToSave(from viewController: UIViewController?) {
        let alertStyle: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
        let alert = UIAlertController(title: nil, message: TextContent.savePromptMessage, preferredStyle: alertStyle)
        alert.addAction(UIAlertAction(title: TextContent.savePromptSaveButton, style: .default, handler: { _ in
            self.saveTapped()
        }))
        alert.addAction(UIAlertAction(title: TextContent.savePromptDiscardButton, style: .destructive, handler: { _ in
            self.dismiss()
        }))
        alert.addCancelActionWithTitle(TextContent.savePromptCancelButton, handler: nil)
        viewController?.present(alert, animated: true, completion: nil)
    }

    fileprivate enum TextContent {
        static let title = NSLocalizedString("stats.insights.management.title", value: "Manage Stats Cards", comment: "Title of the Stats Insights Management screen")
        static let activeCardsHeader = NSLocalizedString("stats.insights.management.activeCards", value: "Active Cards", comment: "Header title indicating which Stats Insights cards the user currently has set to active.")
        static let inactiveCardsHeader = NSLocalizedString("stats.insights.management.inactiveCards", value: "Inactive Cards", comment: "Header title indicating which Stats Insights cards the user currently has disabled.")
        static let placeholderRowTitle = NSLocalizedString("stats.insights.management.selectCardsPrompt", value: "Select cards from the list below", comment: "Prompt displayed on the Stats Insights management screen telling the user to tap a row to add it to their list of active cards.")
        static let inactivePlaceholderRowTitle = NSLocalizedString("stats.insights.management.noCardsPrompt", value: "No inactive cards remaining", comment: "Prompt displayed on the Stats Insights management screen telling the user that all Stats cards are enabled.")

        static let savePromptMessage = NSLocalizedString("stats.insights.management.savePrompt.message", value: "You've made changes to your active Insights cards.", comment: "Title of alert in Stats Insights management, prompting the user to save changes to their list of active Stats cards.")
        static let savePromptSaveButton = NSLocalizedString("stats.insights.management.savePrompt.saveButton", value: "Save Changes", comment: "Title of button in Stats Insights management, prompting the user to save changes to their list of active Stats cards.")
        static let savePromptDiscardButton = NSLocalizedString("stats.insights.management.savePrompt.discardButton", value: "Discard Changes", comment: "Title of button in Stats Insights management, prompting the user to discard changes to their list of active Stats cards.")
        static let savePromptCancelButton = NSLocalizedString("stats.insights.management.savePrompt.cancelButton", value: "Cancel", comment: "Title of button to cancel an alert and take no action.")
    }
}

private extension InsightsManagementViewController {

    // MARK: - Table Model

    func reloadViewModel() {
        tableHandler.viewModel = tableViewModel()
        tableView.reloadData()
    }

    func tableViewModel() -> ImmuTable {
        if AppConfiguration.statsRevampV2Enabled {
            return ImmuTable(sections: [ selectedStatsSection(),
                                         inactiveCardsSection() ].compactMap({$0})
            )
        } else {
            return ImmuTable(sections: [ selectedStatsSection(),
                                         sectionForCategory(.general),
                                         sectionForCategory(.postsAndPages),
                                         sectionForCategory(.activity) ].compactMap({$0})
            )
        }
    }

    // MARK: - Table Sections

    func selectedStatsSection() -> ImmuTableSection? {
        guard AppConfiguration.statsRevampV2Enabled else {
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

    func inactiveCardsSection() -> ImmuTableSection {
        let rows = insightsInactive

        guard rows.count > 0 else {
            return ImmuTableSection(headerText: TextContent.inactiveCardsHeader, rows: [inactivePlaceholderRow])
        }

        return ImmuTableSection(headerText: TextContent.inactiveCardsHeader,
                                rows: rows.map {
                                    return AddInsightStatRow(title: $0.insightManagementTitle,
                                                             enabled: false,
                                                             action: rowActionFor($0)) }
        )
    }

    func sectionForCategory(_ category: InsightsCategories) -> ImmuTableSection? {
        guard AppConfiguration.statsRevampV2Enabled else {
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
            if AppConfiguration.statsRevampV2Enabled {
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
            moveRowToInactive(at: index, statSection: statSection)
        } else if let inactiveIndex = insightsInactive.firstIndex(of: statSection) {
            insightsShown.append(statSection)
            moveRowToActive(at: inactiveIndex, statSection: statSection)
        }
    }

    // Animates the movement of a row from the inactive to active section, supports accessibility
    func moveRowToActive(at index: Int, statSection: StatSection) {
        tableHandler.viewModel = tableViewModel()

        let origin = IndexPath(row: index, section: 1)
        let row = insightsShown.firstIndex(of: statSection) ?? (insightsShown.count - 1)
        let destination = IndexPath(row: row, section: 0)

        tableView.performBatchUpdates {
            tableView.moveRow(at: origin, to: destination)

            /// Account for placeholder cell addition to inactive section
            if insightsInactive.isEmpty {
                tableView.insertRows(at: [.init(row: 0, section: 1)], with: .none)
            }

            /// Account for placeholder cell removal from active section
            if insightsShown.count == 1 {
                tableView.deleteRows(at: [.init(row: 0, section: 0)], with: .automatic)
            }
        }

        /// Reload the data of the row to update the accessibility information
        if let cell = tableView.cellForRow(at: destination), insightsShown.count > 0 {
            tableHandler.viewModel.rowAtIndexPath(destination).configureCell(cell)
        }
    }

    // Animates the movement of a row from the active to inactive section, supports accessibility
    func moveRowToInactive(at index: Int, statSection: StatSection) {
        tableHandler.viewModel = tableViewModel()

        let origin = IndexPath(row: index, section: 0)
        let row = insightsInactive.firstIndex(of: statSection) ?? 0
        let destination = IndexPath(row: row, section: 1)

        tableView.performBatchUpdates {
            tableView.moveRow(at: origin, to: destination)

            /// Account for placeholder cell addition to active section
            if insightsShown.isEmpty {
                tableView.insertRows(at: [.init(row: 0, section: 0)], with: .none)
            }

            /// Account for placeholder cell removal from inactive section
            if insightsInactive.count == 1 {
                tableView.deleteRows(at: [.init(row: 0, section: 1)], with: .automatic)
            }
        }

        /// Reload the data of the row to update the accessibility information
        if let cell = tableView.cellForRow(at: destination), insightsInactive.count > 0 {
            tableHandler.viewModel.rowAtIndexPath(destination).configureCell(cell)
        }
    }

    var placeholderRow: ImmuTableRow {
        return AddInsightStatRow(title: TextContent.placeholderRowTitle,
                                 enabled: false,
                                 action: nil)
    }

    var inactivePlaceholderRow: ImmuTableRow {
        return AddInsightStatRow(title: TextContent.inactivePlaceholderRowTitle,
                                 enabled: false,
                                 action: nil)
    }

    /// Insight StatSections who share the same insightType are represented by a single card
    /// Only display a single one of them for Insight Management
    /// insightsCommentsPosts and insightsCommentsAuthors have the same insightType
    /// insightsFollowersEmail and insightsFollowersWordpress have the same insightType
    private static let insightsNotSupportedForManagement: [StatSection] = [
        .insightsFollowersWordPress,
        .insightsCommentsAuthors
    ]

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
                if AppConfiguration.statsRevampV2Enabled {
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
