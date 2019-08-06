import UIKit

class AddInsightTableViewController: UITableViewController {

    // MARK: - Properties

    weak var insightsDelegate: SiteStatsInsightsDelegate?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Init

    override init(style: UITableView.Style) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Add New Stats Card", comment: "Add New Stats Card view title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([AddInsightStatRow.self], tableView: tableView)
        reloadViewModel()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        tableView.accessibilityIdentifier = "Add Insight Table"
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 38
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

}

private extension AddInsightTableViewController {

    // MARK: - Table Model

    func reloadViewModel() {
        tableHandler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        return ImmuTable(sections: [ sectionForCategory(.general),
                                     sectionForCategory(.postsAndPages),
                                     sectionForCategory(.activity) ]
        )
    }

    // MARK: - Table Sections

    func sectionForCategory(_ category: InsightsCategories) -> ImmuTableSection {
        return ImmuTableSection(headerText: category.title,
                                rows: category.insights.map { AddInsightStatRow(title: $0.insightManagementTitle,
                                                                                enabled: true,
                                                                                action: rowActionFor($0)) }
        )
    }

    func rowActionFor(_ statSection: StatSection) -> ImmuTableAction {
        return { [unowned self] row in
            self.insightsDelegate?.addInsightSelected?(statSection)
            self.navigationController?.popViewController(animated: true)
        }
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
                return [.insightsAllTime, .insightsMostPopularTime, .insightsAnnualSiteStats, .insightsTodaysStats]
            case .postsAndPages:
                return [.insightsLatestPostSummary, .insightsPostingActivity, .insightsTagsAndCategories]
            case .activity:
                return [.insightsCommentsPosts, .insightsFollowersEmail, .insightsFollowerTotals, .insightsPublicize]
            }
        }
    }

}
