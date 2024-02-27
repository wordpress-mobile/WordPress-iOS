import UIKit
import WordPressFlux
import Combine

@objc protocol SiteStatsPeriodDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
    @objc optional func barChartTabSelected(_ tabIndex: StatsTrafficBarChartTabIndex)
}

protocol SiteStatsReferrerDelegate: AnyObject {
    func showReferrerDetails(_ data: StatsTotalRowData)
}

final class SiteStatsPeriodTableViewController: SiteStatsBaseTableViewController {
    static var defaultStoryboardName: String = "SiteStatsDashboard"

    weak var bannerView: JetpackBannerView?

    // MARK: - Properties

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private let store = StoreContainer.shared.statsPeriod
    private var changeReceipt: Receipt?

    private var viewModel: SiteStatsPeriodViewModel!
    private let datePickerViewModel: StatsTrafficDatePickerViewModel
    private let datePickerView: StatsTrafficDatePickerView
    private var cancellables: Set<AnyCancellable> = []

    private let analyticsTracker = BottomScrollAnalyticsTracker()

    private lazy var tableHandler: ImmuTableDiffableViewHandler = {
        return ImmuTableDiffableViewHandler(takeOver: self, with: analyticsTracker)
    }()

    init(selectedDate: Date, selectedPeriod: StatsPeriodUnit) {
        datePickerViewModel = StatsTrafficDatePickerViewModel(period: selectedPeriod, date: selectedDate)
        datePickerView = StatsTrafficDatePickerView(viewModel: datePickerViewModel)
        super.init(nibName: nil, bundle: nil)
        tableStyle = .insetGrouped
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        clearExpandedRows()
        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl.addTarget(self, action: #selector(userInitiatedRefresh), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableView.estimatedRowHeight = 500
        tableView.estimatedSectionHeaderHeight = SiteStatsTableHeaderView.estimatedHeight
        sendScrollEventsToBanner()

        viewModel = SiteStatsPeriodViewModel(store: store,
                                             selectedDate: datePickerViewModel.date,
                                             selectedPeriod: datePickerViewModel.period,
                                             periodDelegate: self,
                                             referrerDelegate: self)
        addViewModelListeners()
        viewModel.startFetchingOverview()

        Publishers.CombineLatest(datePickerViewModel.$date, datePickerViewModel.$period)
            .sink(receiveValue: { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.refreshData()
                }
            })
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isMovingToParent {
            addViewModelListeners()
            viewModel.refreshTrafficOverviewData(withDate: datePickerViewModel.date, forPeriod: datePickerViewModel.period)
        }
    }

    override func initTableView() {
        let embeddedDatePickerView = UIView.embedSwiftUIView(datePickerView)
        view.addSubview(embeddedDatePickerView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: embeddedDatePickerView.topAnchor, constant: 0),
            view.leadingAnchor.constraint(equalTo: embeddedDatePickerView.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: embeddedDatePickerView.trailingAnchor, constant: 0),
            embeddedDatePickerView.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: 0),
            view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])

        tableView.refreshControl = refreshControl
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return UITableView.automaticDimension
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }

}

// MARK: - Private Extension

private extension SiteStatsPeriodTableViewController {

    // MARK: - View Model

    func addViewModelListeners() {
        if changeReceipt != nil {
            return
        }

        changeReceipt = viewModel.onChange { [weak self] in
            self?.refreshTableView()
        }
    }

    func removeViewModelListeners() {
        changeReceipt = nil
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [PeriodEmptyCellHeaderRow.self,
                CellHeaderRow.self,
                TopTotalsPeriodStatsRow.self,
                TopTotalsNoSubtitlesPeriodStatsRow.self,
                CountriesStatsRow.self,
                CountriesMapRow.self,
                StatsTrafficBarChartRow.self,
                TableFooterRow.self,
                StatsErrorRow.self,
                StatsGhostChartImmutableRow.self,
                StatsGhostTopImmutableRow.self,
                TwoColumnStatsRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        tableHandler.diffableDataSource.apply(viewModel.tableViewSnapshot(), animatingDifferences: false)

        refreshControl.endRefreshing()
//        tableHeaderView?.animateGhostLayers(viewModel.isFetchingChart() == true)

        if viewModel.fetchingFailed() {
            displayFailureViewIfNecessary()
        }
    }

    @objc func userInitiatedRefresh() {
        clearExpandedRows()
        refreshControl.beginRefreshing()
        refreshData()
    }

    func refreshData() {
        guard viewIsVisible() else {
            refreshControl.endRefreshing()
            return
        }
        addViewModelListeners()
        viewModel.refreshTrafficOverviewData(withDate: datePickerViewModel.date, forPeriod: datePickerViewModel.period)
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
    private func displayFailureViewIfNecessary() {
        guard tableHandler.diffableDataSource.snapshot().numberOfSections == 0 else {
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

extension SiteStatsPeriodTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        hideNoResults()
        refreshData()
    }
}

// MARK: - SiteStatsPeriodDelegate Methods

extension SiteStatsPeriodTableViewController: SiteStatsPeriodDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: "site_stats_period")
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func displayMediaWithID(_ mediaID: NSNumber) {

        guard let siteID = SiteStatsInformation.sharedInstance.siteID, let blog = Blog.lookup(withID: siteID, in: mainContext) else {
            DDLogInfo("Unable to get blog when trying to show media from Stats.")
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
                DDLogInfo("Unable to get media when trying to show from Stats: \(error.localizedDescription)")
                return
            }

            let viewController = MediaItemViewController(media: media)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool) {
        if didSelectRow {
            applyTableUpdates()
        }
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allPeriods.contains(statSection) else {
            return
        }

        removeViewModelListeners()

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection,
                                            selectedDate: datePickerViewModel.date,
                                            selectedPeriod: datePickerViewModel.period)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        removeViewModelListeners()

        let postStatsTableViewController = PostStatsTableViewController.withJPBannerForBlog(postID: postID,
                                                                                            postTitle: postTitle,
                                                                                            postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    func barChartTabSelected(_ tabIndex: StatsTrafficBarChartTabIndex) {
        if let tab = StatsTrafficBarChartTabs(rawValue: tabIndex) {
            trackBarChartTabSelectionEvent(tab: tab, period: datePickerViewModel.period)
        }
    }
}

// MARK: - SiteStatsReferrerDelegate

extension SiteStatsPeriodTableViewController: SiteStatsReferrerDelegate {
    func showReferrerDetails(_ data: StatsTotalRowData) {
        show(ReferrerDetailsTableViewController(data: data), sender: nil)
    }
}

// MARK: Jetpack powered banner

private extension SiteStatsPeriodTableViewController {

    func sendScrollEventsToBanner() {
        if let bannerView = bannerView {
            analyticsTracker.addTranslationObserver(bannerView)
        }
    }
}

// MARK: - Tracking

private extension SiteStatsPeriodTableViewController {
    func trackBarChartTabSelectionEvent(tab: StatsTrafficBarChartTabs, period: StatsPeriodUnit) {
        let properties: [AnyHashable: Any] = [StatsPeriodUnit.analyticsPeriodKey: period.description as Any]
        WPAppAnalytics.track(tab.analyticsEvent, withProperties: properties)

    }
}
