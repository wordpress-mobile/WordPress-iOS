import UIKit
import WordPressFlux

@objc protocol SiteStatsDetailsDelegate {
    @objc optional func tabbedTotalsCellUpdated()
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
}

class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private var statType: StatType = .period
    private var selectedDate: Date?
    private var selectedPeriod: StatsPeriodUnit?

    private var viewModel: SiteStatsDetailsViewModel?
    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsChangeReceipt: Receipt?
    private let periodStore = StoreContainer.shared.statsPeriod
    private var periodChangeReceipt: Receipt?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private var postID: Int?
    private let siteID = SiteStatsInformation.sharedInstance.siteID

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var mediaService: MediaService = {
        return MediaService(managedObjectContext: mainContext)
    }()

    private lazy var blogService: BlogService = {
        return BlogService(managedObjectContext: mainContext)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        clearExpandedRows()
        Style.configureTable(tableView)
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
    }

    func configure(statSection: StatSection,
                   selectedDate: Date? = nil,
                   selectedPeriod: StatsPeriodUnit? = nil,
                   postID: Int? = nil) {
        self.statSection = statSection
        self.selectedDate = selectedDate
        self.selectedPeriod = selectedPeriod
        self.postID = postID
        statType = StatSection.allInsights.contains(statSection) ? .insights : .period
        title = statSection.title
        initViewModel()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // This is primarily to resize the NoResultsView in a TabbedTotalsCell on rotation.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        })
    }

}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func initViewModel() {
        viewModel = SiteStatsDetailsViewModel(detailsDelegate: self)

        guard let statSection = statSection else {
            return
        }

        viewModel?.fetchDataFor(statSection: statSection,
                                selectedDate: selectedDate,
                                selectedPeriod: selectedPeriod,
                                postID: postID)

        if statType == .insights {
            insightsChangeReceipt = viewModel?.onChange { [weak self] in
                guard self?.storeIsFetching(statSection: statSection) == false else {
                    return
                }
                self?.refreshTableView()
            }
        } else {
            periodChangeReceipt = viewModel?.onChange { [weak self] in
                guard self?.storeIsFetching(statSection: statSection) == false else {
                    return
                }
                self?.refreshTableView()
            }
        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [DetailDataRow.self,
                DetailSubtitlesHeaderRow.self,
                TabbedTotalsDetailStatsRow.self,
                TopTotalsDetailStatsRow.self,
                CountriesDetailStatsRow.self,
                TopTotalsNoSubtitlesPeriodDetailStatsRow.self]
    }

    func storeIsFetching(statSection: StatSection) -> Bool {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return insightsStore.isFetchingFollowers
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            return insightsStore.isFetchingComments
        case .insightsTagsAndCategories:
            return insightsStore.isFetchingTagsAndCategories
        case .periodPostsAndPages:
            return periodStore.isFetchingPostsAndPages
        case .periodSearchTerms:
            return periodStore.isFetchingSearchTerms
        case .periodVideos:
            return periodStore.isFetchingVideos
        case .periodClicks:
            return periodStore.isFetchingClicks
        case .periodAuthors:
            return periodStore.isFetchingAuthors
        case .periodReferrers:
            return periodStore.isFetchingReferrers
        case .periodCountries:
            return periodStore.isFetchingCountries
        case .periodPublished:
            return periodStore.isFetchingPublished
        case .postStatsMonthsYears, .postStatsAverageViews:
            return periodStore.isFetchingPostStats
        default:
            return false
        }
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
        refreshControl?.endRefreshing()
    }

    @objc func refreshData() {
        guard let statSection = statSection else {
            return
        }

        clearExpandedRows()
        refreshControl?.beginRefreshing()

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            viewModel?.refreshFollowers()
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            viewModel?.refreshComments()
        case .insightsTagsAndCategories:
            viewModel?.refreshTagsAndCategories()
        case .periodPostsAndPages:
            viewModel?.refreshPostsAndPages()
        case .periodSearchTerms:
            viewModel?.refreshSearchTerms()
        case .periodVideos:
            viewModel?.refreshVideos()
        case .periodClicks:
            viewModel?.refreshClicks()
        case .periodAuthors:
            viewModel?.refreshAuthors()
        case .periodReferrers:
            viewModel?.refreshReferrers()
        case .periodCountries:
            viewModel?.refreshCountries()
        case .periodPublished:
            viewModel?.refreshPublished()
        case .postStatsMonthsYears, .postStatsAverageViews:
            viewModel?.refreshPostStats()
        default:
            refreshControl?.endRefreshing()
        }
    }

    func applyTableUpdates() {
        if #available(iOS 11.0, *) {
            tableView.performBatchUpdates({
                updateStatSectionForFilterChange()
            })
        } else {
            tableView.beginUpdates()
            updateStatSectionForFilterChange()
            tableView.endUpdates()
        }
    }

    func clearExpandedRows() {
        StatsDataHelper.clearExpandedDetails()
    }

    func updateStatSectionForFilterChange() {
        guard let oldStatSection = statSection else {
            return
        }

        switch oldStatSection {
        case .insightsFollowersWordPress:
            statSection = .insightsFollowersEmail
        case .insightsFollowersEmail:
            statSection = .insightsFollowersWordPress
        case .insightsCommentsAuthors:
            statSection = .insightsCommentsPosts
        case .insightsCommentsPosts:
            statSection = .insightsCommentsAuthors
        default:
            // Return here as `initViewModel` is only needed for filtered cards.
            return
        }

        initViewModel()
    }

}

// MARK: - SiteStatsDetailsDelegate Methods

extension SiteStatsDetailTableViewController: SiteStatsDetailsDelegate {

    func tabbedTotalsCellUpdated() {
        applyTableUpdates()
    }

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func expandedRowUpdated(_ row: StatsTotalRow) {
        applyTableUpdates()
        StatsDataHelper.updatedExpandedState(forRow: row, inDetails: true)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        let postStatsTableViewController = PostStatsTableViewController.loadFromStoryboard()
        postStatsTableViewController.configure(postID: postID, postTitle: postTitle, postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {

        guard let siteID = siteID,
            let blog = blogService.blog(byBlogId: siteID) else {
                DDLogInfo("Unable to get blog when trying to show media from Stats details.")
                return
        }

        mediaService.getMediaWithID(mediaID, in: blog, success: { (media) in
            let viewController = MediaItemViewController(media: media)
            self.navigationController?.pushViewController(viewController, animated: true)
        }, failure: { (error) in
            DDLogInfo("Unable to get media when trying to show from Stats details: \(error.localizedDescription)")
        })
    }

}
