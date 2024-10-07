import UIKit
import WordPressFlux
import Combine

@objc protocol SiteStatsPeriodDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func displayMediaWithID(_ mediaID: NSNumber)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
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

    private let store = StatsPeriodStore()
    private var changeReceipt: Receipt?

    private var viewModel: SiteStatsPeriodViewModel!
    private let datePickerViewModel: StatsTrafficDatePickerViewModel
    private let datePickerView: StatsTrafficDatePickerView
    private var cancellables: Set<AnyCancellable> = []

    private let analyticsTracker = BottomScrollAnalyticsTracker()

    private lazy var tableHandler: ImmuTableDiffableViewHandler = {
        return ImmuTableDiffableViewHandler(takeOver: self, with: analyticsTracker)
    }()

    init(date: Date, period: StatsPeriodUnit) {
        datePickerViewModel = StatsTrafficDatePickerViewModel(period: period, date: date)
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
        tableView.cellLayoutMarginsFollowReadableWidth = true
        sendScrollEventsToBanner()

        viewModel = SiteStatsPeriodViewModel(store: store,
                                             selectedDate: datePickerViewModel.date,
                                             selectedPeriod: datePickerViewModel.period,
                                             periodDelegate: self,
                                             referrerDelegate: self)
        viewModel?.statsBarChartViewDelegate = self
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

        addViewModelListeners()
        viewModel.addListeners()
        viewModel.refreshTrafficOverviewData(withDate: datePickerViewModel.date, forPeriod: datePickerViewModel.period)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        removeViewModelListeners()
        viewModel.removeListeners()
    }

    override func initTableView() {
        let embeddedDatePickerView = UIView.embedSwiftUIView(datePickerView)
        view.addSubview(embeddedDatePickerView)
        embeddedDatePickerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: embeddedDatePickerView.topAnchor, constant: 0),
            view.readableContentGuide.leadingAnchor.constraint(equalTo: embeddedDatePickerView.leadingAnchor, constant: 0),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: embeddedDatePickerView.trailingAnchor, constant: 0),
            embeddedDatePickerView.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: 0),
            view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])

        let divider = UIView()
        divider.backgroundColor = .separator

        view.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: embeddedDatePickerView.bottomAnchor)
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

    func refreshData() {
        guard viewIsVisible() else {
            refreshControl.endRefreshing()
            return
        }
        addViewModelListeners()
        viewModel.refreshTrafficOverviewData(withDate: datePickerViewModel.date, forPeriod: datePickerViewModel.period)
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
                OverviewRow.self,
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

        if viewModel.fetchingFailed() {
            displayFailureViewIfNecessary()
        }
    }

    @objc func userInitiatedRefresh() {
        clearExpandedRows()
        refreshControl.beginRefreshing()
        refreshData()
    }

    func applyTableUpdates() {
        tableHandler.diffableDataSource.apply(viewModel.tableViewSnapshot(), animatingDifferences: false)
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
}

extension SiteStatsPeriodTableViewController: StatsBarChartViewDelegate {
    func statsBarChartTabSelected(_ tabIndex: Int) {
        viewModel.currentTabIndex = tabIndex
    }

    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        if let selectedChartDate = viewModel?.chartDate(for: entryIndex) {
            datePickerViewModel.updateDate(selectedChartDate)
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
