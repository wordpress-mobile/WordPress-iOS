import UIKit
import WordPressFlux

class SiteStatsInsightsDetailsTableViewController: SiteStatsBaseTableViewController {

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private var statType: StatType = .period
    private var selectedDate = StatsDataHelper.currentDateForSite()
    private var selectedPeriod: StatsPeriodUnit?

    private var viewModel: SiteStatsInsightsDetailsViewModel?
    private var tableHeaderView: SiteStatsTableHeaderView?

    private var receipt: Receipt?

    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsChangeReceipt: Receipt?
    private let periodStore = StoreContainer.shared.statsPeriod
    private var periodChangeReceipt: Receipt?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private var postID: Int?

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var mediaService: MediaService = {
        return MediaService(managedObjectContext: mainContext)
    }()

    private lazy var blogService: BlogService = {
        return BlogService(managedObjectContext: mainContext)
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.estimatedSectionHeaderHeight = SiteStatsTableHeaderView.estimatedHeight
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        addWillEnterForegroundObserver()
    }

    func configure(statSection: StatSection,
                   selectedDate: Date? = nil,
                   selectedPeriod: StatsPeriodUnit? = nil,
                   postID: Int? = nil
    ) {
        self.statSection = statSection
        self.selectedDate = selectedDate ?? StatsDataHelper.currentDateForSite()
        self.selectedPeriod = selectedPeriod
        self.postID = postID
        tableStyle = .insetGrouped
        statType = StatSection.allInsights.contains(statSection) ? .insights : .period
        title = statSection.detailsTitle
        initViewModel()
        updateHeader()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // This is primarily to resize the NoResultsView in a TabbedTotalsCell on rotation.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        })
    }
}

extension SiteStatsInsightsDetailsTableViewController: StatsForegroundObservable {
    func reloadStatsData() {
        selectedDate = StatsDataHelper.currentDateForSite()
        refreshData()
    }
}

private extension SiteStatsInsightsDetailsTableViewController {
    private func updateHeader() {
        guard let siteStatsTableHeaderView = Bundle.main.loadNibNamed("SiteStatsTableHeaderView", owner: nil, options: nil)?.first as? SiteStatsTableHeaderView else {
            return
        }

        // When section header is this year, we configure the header so it shows only year
        if let statSection = statSection,
              statSection == .insightsAnnualSiteStats,
              let allAnnualInsights = insightsStore.getAllAnnual()?.allAnnualInsights,
              let mostRecentYear = allAnnualInsights.last?.year {
            // Allow the date bar to only go up to the most recent year available.
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: StatsDataHelper.currentDateForSite())
            dateComponents.year = mostRecentYear
            let mostRecentDate = Calendar.current.date(from: dateComponents)

            siteStatsTableHeaderView.configure(date: selectedDate,
                    period: .year,
                    delegate: self,
                    expectedPeriodCount: allAnnualInsights.count,
                    mostRecentDate: mostRecentDate)
        }
        else {
            siteStatsTableHeaderView.configure(date: selectedDate, period: StatsPeriodUnit.week, delegate: self)
        }

        if let statSection = statSection {
            siteStatsTableHeaderView.animateGhostLayers(viewModel?.storeIsFetching(statSection: statSection) == true)
        }

        tableView.tableHeaderView = siteStatsTableHeaderView

        guard let tableHeaderView = tableView.tableHeaderView else {
            return
        }

        tableHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableHeaderView.topAnchor.constraint(equalTo: tableView.topAnchor),
            tableHeaderView.safeLeadingAnchor.constraint(equalTo: tableView.safeLeadingAnchor),
            tableHeaderView.safeTrailingAnchor.constraint(equalTo: tableView.safeTrailingAnchor),
            tableHeaderView.heightAnchor.constraint(equalToConstant: 60)
        ])
        tableView.tableHeaderView?.layoutIfNeeded()
    }

    func initViewModel() {
        viewModel = SiteStatsInsightsDetailsViewModel(detailsDelegate: self,
                referrerDelegate: self)

        guard let statSection = statSection else {
            return
        }

        receipt = viewModel?.onChange { [weak self] in
            self?.updateHeader()
            self?.refreshTableView()
        }

        viewModel?.fetchDataFor(statSection: statSection,
                selectedDate: selectedDate,
                selectedPeriod: selectedPeriod,
                postID: postID)
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [DetailDataRow.self,
                DetailExpandableRow.self,
                DetailExpandableChildRow.self,
                DetailSubtitlesHeaderRow.self,
                DetailSubtitlesTabbedHeaderRow.self,
                DetailSubtitlesCountriesHeaderRow.self,
                CountriesMapRow.self,
                StatsErrorRow.self,
                StatsGhostTopHeaderImmutableRow.self,
                StatsGhostDetailRow.self,
                ViewsVisitorsRow.self,
                PeriodEmptyCellHeaderRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
        refreshControl.endRefreshing()

        if viewModel.fetchDataHasFailed() {
            displayFailureViewIfNecessary()
        } else {
            hideNoResults()
        }
    }

    @objc func refreshData() {
        guard let statSection = statSection else {
            return
        }

        clearExpandedRows()
        refreshControl.beginRefreshing()

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            viewModel?.refreshFollowers()
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            viewModel?.refreshComments()
        case .insightsTagsAndCategories:
            viewModel?.refreshTagsAndCategories()
        case .insightsAnnualSiteStats:
            viewModel?.refreshAnnual(selectedDate: selectedDate)
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
        case .periodFileDownloads:
            viewModel?.refreshFileDownloads()
        case .postStatsMonthsYears, .postStatsAverageViews:
            viewModel?.refreshPostStats()
        default:
            refreshControl.endRefreshing()
        }
    }

    func applyTableUpdates() {
        tableView.performBatchUpdates({
            updateStatSectionForFilterChange()
        })
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

extension SiteStatsInsightsDetailsTableViewController: SiteStatsDetailsDelegate {

    func tabbedTotalsCellUpdated() {
        updateStatSectionForFilterChange()
    }

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: "site_stats_detail")
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func toggleChildRowsForRow(_ row: StatsTotalRow) {
        StatsDataHelper.updatedExpandedState(forRow: row, inDetails: true)
        refreshTableView()
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        let postStatsTableViewController = PostStatsTableViewController.loadFromStoryboard()
        postStatsTableViewController.configure(postID: postID, postTitle: postTitle, postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {

        guard let siteID = SiteStatsInformation.sharedInstance.siteID,
              let blog = Blog.lookup(withID: siteID, in: mainContext) else {
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

// MARK: - SiteStatsReferrerDelegate

extension SiteStatsInsightsDetailsTableViewController: SiteStatsReferrerDelegate {
    func showReferrerDetails(_ data: StatsTotalRowData) {
        show(ReferrerDetailsTableViewController(data: data), sender: nil)
    }
}

// MARK: - NoResultsViewHost

extension SiteStatsInsightsDetailsTableViewController: NoResultsViewHost {

    private func displayFailureViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        configureAndDisplayNoResults(on: tableView,
                title: NoResultConstants.errorTitle,
                subtitle: NoResultConstants.errorSubtitle,
                buttonTitle: NoResultConstants.refreshButtonTitle, customizationBlock: { [weak self] noResults in
            noResults.delegate = self
            if !noResults.isReachable {
                noResults.resetButtonText()
            }
        })
    }

    private enum NoResultConstants {
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
        static let errorSubtitle = NSLocalizedString("There was a problem loading your data, refresh your page to try again.", comment: "The loading view subtitle displayed when an error occurred")
        static let refreshButtonTitle = NSLocalizedString("Refresh", comment: "The loading view button title displayed when an error occurred")
    }
}

// MARK: - NoResultsViewControllerDelegate methods

extension SiteStatsInsightsDetailsTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        hideNoResults()
        refreshData()
    }
}

// MARK: - SiteStatsTableHeaderDelegate Methods

extension SiteStatsInsightsDetailsTableViewController: SiteStatsTableHeaderDelegate {

    func dateChangedTo(_ newDate: Date?) {
        guard let newDate = newDate else {
            return
        }

        // Since all Annual insights have already been fetched, don't refetch.
        // Just update the date in the view model and refresh the table.
        selectedDate = newDate
        viewModel?.updateSelectedDate(newDate)
        refreshTableView()
    }
}
