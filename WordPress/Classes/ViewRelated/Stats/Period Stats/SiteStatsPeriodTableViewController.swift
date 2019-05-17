import UIKit
import WordPressFlux


@objc protocol SiteStatsPeriodDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
}


class SiteStatsPeriodTableViewController: UITableViewController {

    // MARK: - Properties

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

    var selectedDate: Date?
    var selectedPeriod: StatsPeriodUnit? {
        didSet {

            guard selectedPeriod != nil else {
                return
            }

            clearExpandedRows()

            // If this is the first time setting the Period, need to initialize the view model.
            // Otherwise, just refresh the data.
            if oldValue == nil {
                initViewModel()
            } else {
                refreshData()
            }

            displayLoadingViewIfNecessary()
        }
    }

    private let store = StoreContainer.shared.statsPeriod
    private var changeReceipt: Receipt?

    private var viewModel: SiteStatsPeriodViewModel?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        clearExpandedRows()
        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl?.addTarget(self, action: #selector(userInitiatedRefresh), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableView.register(SiteStatsTableHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: SiteStatsTableHeaderView.defaultNibName)
        tableView.estimatedRowHeight = 500
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: SiteStatsTableHeaderView.defaultNibName) as? SiteStatsTableHeaderView else {
            return nil
        }

        cell.configure(date: selectedDate, period: selectedPeriod, delegate: self)
        viewModel?.statsBarChartViewDelegate = cell

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteStatsTableHeaderView.height
    }

}

// MARK: - Private Extension

private extension SiteStatsPeriodTableViewController {

    // MARK: - View Model

    func initViewModel() {

        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                return
        }

        viewModel = SiteStatsPeriodViewModel(store: store,
                                             selectedDate: selectedDate,
                                             selectedPeriod: selectedPeriod,
                                             periodDelegate: self)

        changeReceipt = viewModel?.onChange { [weak self] in
            self?.refreshTableView()
        }

        viewModel?.overviewStoreStatusOnChange = { [weak self] status in
            guard let self = self,
                let viewModel = self.viewModel,
                self.viewIsVisible() else {
                return
            }

            self.tableHandler.viewModel = viewModel.tableViewModel()

            switch status {
            case .fetchingData:
                self.displayLoadingViewIfNecessary()
            case .fetchingCacheData(let hasCache):
                if hasCache {
                    self.hideNoResults()
                }
            case .fetchingDataCompleted(let error):
                if error {
                    self.displayFailureViewIfNecessary()
                } else {
                    self.hideNoResults()
                }
            }
        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [CellHeaderRow.self,
                TopTotalsPeriodStatsRow.self,
                TopTotalsNoSubtitlesPeriodStatsRow.self,
                CountriesStatsRow.self,
                OverviewRow.self,
                TableFooterRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel,
            viewIsVisible(),
            !store.isFetchingOverview else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
        refreshControl?.endRefreshing()
    }

    @objc func userInitiatedRefresh() {
        clearExpandedRows()
        refreshControl?.beginRefreshing()
        refreshData()
    }

    func refreshData() {

        guard let selectedDate = selectedDate,
            let selectedPeriod = selectedPeriod else {
                refreshControl?.endRefreshing()
                return
        }

        viewModel?.refreshPeriodOverviewData(withDate: selectedDate, forPeriod: selectedPeriod)
    }

    func applyTableUpdates() {
        tableView.performBatchUpdates({
        })
    }

    func clearExpandedRows() {
        StatsDataHelper.clearExpandedPeriods()
    }

    func viewIsVisible() -> Bool {
        return isViewLoaded && view.window != nil
    }

}

// MARK: - NoResultsViewHost

extension SiteStatsPeriodTableViewController: NoResultsViewHost {
    private func displayLoadingViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        if noResultsViewController.view.superview != nil {
            return
        }

        configureAndDisplayNoResults(on: tableView,
                                     title: NoResultConstants.successTitle,
                                     accessoryView: NoResultsViewController.loadingAccessoryView()) { [weak self] noResults in
                                        noResults.delegate = self
                                        noResults.hideImageView(false)
        }
    }

    private func displayFailureViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        updateNoResults(title: NoResultConstants.errorTitle,
                        subtitle: NoResultConstants.errorSubtitle,
                        buttonTitle: NoResultConstants.refreshButtonTitle) { [weak self] noResults in
                            noResults.delegate = self
                            noResults.hideImageView()
        }
    }

    private enum NoResultConstants {
        static let successTitle = NSLocalizedString("Loading Stats...", comment: "The loading view title displayed while the service is loading")
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
        static let errorSubtitle = NSLocalizedString("There was a problem loading your data, refresh your page to try again.", comment: "The loading view subtitle displayed when an error occurred")
        static let refreshButtonTitle = NSLocalizedString("Refresh", comment: "The loading view button title displayed when an error occurred")
    }
}

// MARK: - NoResultsViewControllerDelegate methods

extension SiteStatsPeriodTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        updateNoResults(title: NoResultConstants.successTitle,
                        accessoryView: NoResultsViewController.loadingAccessoryView()) { noResults in
                            noResults.hideImageView(false)
        }
        refreshData()
    }
}

// MARK: - SiteStatsPeriodDelegate Methods

extension SiteStatsPeriodTableViewController: SiteStatsPeriodDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {

        guard let siteID = siteID,
            let blog = blogService.blog(byBlogId: siteID) else {
                DDLogInfo("Unable to get blog when trying to show media from Stats.")
                return
        }

        mediaService.getMediaWithID(mediaID, in: blog, success: { (media) in
            let viewController = MediaItemViewController(media: media)
            self.navigationController?.pushViewController(viewController, animated: true)
        }, failure: { (error) in
            DDLogInfo("Unable to get media when trying to show from Stats: \(error.localizedDescription)")
        })
    }

    func expandedRowUpdated(_ row: StatsTotalRow) {
        applyTableUpdates()
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allPeriods.contains(statSection) else {
            return
        }

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection,
                                            selectedDate: selectedDate,
                                            selectedPeriod: selectedPeriod)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        let postStatsTableViewController = PostStatsTableViewController.loadFromStoryboard()
        postStatsTableViewController.configure(postID: postID, postTitle: postTitle, postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

}

// MARK: - SiteStatsTableHeaderDelegate Methods

extension SiteStatsPeriodTableViewController: SiteStatsTableHeaderDelegate {

    func dateChangedTo(_ newDate: Date?) {
        selectedDate = newDate
        refreshData()
    }

}
