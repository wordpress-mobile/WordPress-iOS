import UIKit
import WordPressFlux

@objc protocol SiteStatsDetailsDelegate {
    @objc optional func tabbedTotalsCellUpdated()
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func toggleChildRowsForRow(_ row: StatsTotalRow)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
}

//TODO - this should eventually be removed as part of Stats Revamp
class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private var selectedDate = StatsDataHelper.currentDateForSite()
    private var selectedPeriod: StatsPeriodUnit?

    private var viewModel: SiteStatsDetailsViewModel?

    private var receipt: Receipt?

    private let insightsStore = StatsInsightsStore()
    private let periodStore = StatsPeriodStore()

    private lazy var tableHandler: ImmuTableDiffableViewHandler = {
        return ImmuTableDiffableViewHandler(takeOver: self, with: nil)
    }()

    private var postID: Int?

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        clearExpandedRows()

        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.estimatedSectionHeaderHeight = SiteStatsTableHeaderView.estimatedHeight
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableView.register(SiteStatsTableHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: SiteStatsTableHeaderView.defaultNibName)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addWillEnterForegroundObserver()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeWillEnterForegroundObserver()
    }

    func configure(statSection: StatSection,
                   selectedDate: Date? = nil,
                   selectedPeriod: StatsPeriodUnit? = nil,
                   postID: Int? = nil) {
        self.statSection = statSection
        self.selectedDate = selectedDate ?? StatsDataHelper.currentDateForSite()
        self.selectedPeriod = selectedPeriod
        self.postID = postID
        title = statSection.detailsTitle
        initViewModel()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // This is primarily to resize the NoResultsView in a TabbedTotalsCell on rotation.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        })
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Only show the date bar for Insights Annual details
        guard let statSection = statSection,
            statSection == .insightsAnnualSiteStats,
            let allAnnualInsights = insightsStore.getAllAnnual()?.allAnnualInsights,
            let mostRecentYear = allAnnualInsights.last?.year else {
            return nil
        }

        guard let cell = Bundle.main.loadNibNamed("SiteStatsTableHeaderView", owner: nil, options: nil)?.first as? SiteStatsTableHeaderView else {
            return nil
        }

        // Allow the date bar to only go up to the most recent year available.
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: StatsDataHelper.currentDateForSite())
        dateComponents.year = mostRecentYear
        let mostRecentDate = Calendar.current.date(from: dateComponents)

        cell.configure(date: selectedDate,
                       period: .year,
                       delegate: self,
                       expectedPeriodCount: allAnnualInsights.count,
                       mostRecentDate: mostRecentDate)
        cell.animateGhostLayers(viewModel?.storeIsFetching(statSection: statSection) == true)
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Only show the date bar for Insights Annual details
        guard let statSection = statSection,
            statSection == .insightsAnnualSiteStats,
            let allAnnualInsights = insightsStore.getAllAnnual()?.allAnnualInsights,
            allAnnualInsights.last?.year != nil else {
            return 0
        }

        return UITableView.automaticDimension
    }

}

extension SiteStatsDetailTableViewController: StatsForegroundObservable {
    func reloadStatsData() {
        selectedDate = StatsDataHelper.currentDateForSite()
        refreshData()
    }
}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func initViewModel() {
        viewModel = SiteStatsDetailsViewModel(detailsDelegate: self,
                                              referrerDelegate: self,
                                              insightsStore: insightsStore,
                                              periodStore: periodStore)

        guard let statSection = statSection else {
            return
        }

        receipt = viewModel?.onChange { [weak self] in
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
                StatsGhostDetailRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.diffableDataSource.apply(viewModel.tableViewSnapshot(), animatingDifferences: false)
        refreshControl?.endRefreshing()

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
        refreshControl?.beginRefreshing()

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
            refreshControl?.endRefreshing()
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
        let postStatsTableViewController = PostStatsTableViewController.withJPBannerForBlog(postID: postID,
                                                                                            postTitle: postTitle,
                                                                                            postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {

        guard let siteID = SiteStatsInformation.sharedInstance.siteID,
              let blog = Blog.lookup(withID: siteID, in: mainContext) else {
                DDLogInfo("Unable to get blog when trying to show media from Stats details.")
                return
        }

        let coreDataStack = ContextManager.shared
        let mediaRepository = MediaRepository(coreDataStack: coreDataStack)
        let blogID = TaggedManagedObjectID(blog)
        Task { @MainActor in
            let media: Media
            do {
                let mediaID = try await mediaRepository.getMedia(withID: mediaID, in: blogID)
                media = try mainContext.existingObject(with: mediaID)
            } catch {
                DDLogInfo("Unable to get media when trying to show from Stats details: \(error.localizedDescription)")
                return
            }

            let viewController = MediaItemViewController(media: media)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - SiteStatsReferrerDelegate

extension SiteStatsDetailTableViewController: SiteStatsReferrerDelegate {
    func showReferrerDetails(_ data: StatsTotalRowData) {
        show(ReferrerDetailsTableViewController(data: data), sender: nil)
    }
}

// MARK: - NoResultsViewHost

extension SiteStatsDetailTableViewController: NoResultsViewHost {

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

extension SiteStatsDetailTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        hideNoResults()
        refreshData()
    }
}

// MARK: - SiteStatsTableHeaderDelegate Methods

extension SiteStatsDetailTableViewController: SiteStatsTableHeaderDelegate {

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
