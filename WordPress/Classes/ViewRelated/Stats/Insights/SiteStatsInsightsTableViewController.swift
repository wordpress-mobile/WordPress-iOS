import UIKit
import WordPressFlux

class SiteStatsInsightsTableViewController: SiteStatsBaseTableViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "SiteStatsDashboard"

    weak var bannerView: JetpackBannerView?

    var isGrowAudienceShowing: Bool {
        return insightsToShow.contains(.growAudience)
    }

    private var insightsChangeReceipt: Receipt?

    // Types of Insights to display. The array order dictates the display order.
    private var insightsToShow: [InsightType] {
        get {
            SiteStatsInformation.sharedInstance.getCurrentSiteInsights()
                .filter(StatSection.allInsights.compactMap(\.insightType).contains)
        }

        set {
            SiteStatsInformation.sharedInstance.saveCurrentSiteInsights(newValue)
        }
    }

    // Local state for site current view count
    private var currentViewCount: Int?

    private lazy var pinnedItemStore: SiteStatsPinnedItemStore? = {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return nil
        }
        return SiteStatsPinnedItemStore(siteId: siteID)
    }()

    private let insightsStore = StoreContainer.shared.statsInsights

    private var viewNeedsUpdating = false
    private var displayingEmptyView = false

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var postService: PostService = {
        return PostService(managedObjectContext: mainContext)
    }()

    private var viewModel: SiteStatsInsightsViewModel?

    private let analyticsTracker = BottomScrollAnalyticsTracker()

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self, with: analyticsTracker)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        SiteStatsInformation.sharedInstance.upgradeInsights()
        clearExpandedRows()
        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        loadPinnedCards()
        initViewModel()
        sendScrollEventsToBanner()
        tableView.estimatedRowHeight = 500
        tableView.rowHeight = UITableView.automaticDimension
        tableView.cellLayoutMarginsFollowReadableWidth = true

        displayEmptyViewIfNecessary()
    }

    func refreshInsights(forceRefresh: Bool = false) {
        addViewModelListeners()
        viewModel?.refreshInsights(forceRefresh: forceRefresh)
    }

    func showAddInsightView(source: String = "table_row") {
        WPAnalytics.track(.statsItemTappedInsightsAddStat, withProperties: ["source": source])
        tableView.deselectSelectedRowWithAnimation(true)

        if displayingEmptyView {
            hideNoResults()
            addViewModelListeners()
            refreshInsights()
        }

        if insightsToShow.contains(.customize) {
            // The view needs to be updated to remove the Customize card.
            // However, if it's done here, there is a weird animation before AddInsight is presented.
            // Instead, set 'viewNeedsUpdating' so the view is updated when 'addInsightDismissed' is called.
            viewNeedsUpdating = true
            dismissCustomizeCard()
        }

        let controller = InsightsManagementViewController(insightsDelegate: self,
                insightsManagementDelegate: self, insightsShown: insightsToShow.compactMap { $0.statSection })
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.presentationController?.delegate = self
        present(navigationController, animated: true, completion: nil)
    }

}

// MARK: - Private Extension

private extension SiteStatsInsightsTableViewController {

    func initViewModel() {
        viewModel = SiteStatsInsightsViewModel(insightsToShow: insightsToShow,
                                               insightsDelegate: self,
                                               viewsAndVisitorsDelegate: self,
                                               insightsStore: insightsStore,
                                               pinnedItemStore: pinnedItemStore)
        addViewModelListeners()
        viewModel?.fetchInsights()
        viewModel?.startFetchingPeriodOverview()
    }

    func addViewModelListeners() {
        if insightsChangeReceipt != nil {
            return
        }

        insightsChangeReceipt = viewModel?.onChange { [weak self] in
            self?.refreshGrowAudienceCardIfNecessary()
            self?.displayEmptyViewIfNecessary()
            self?.refreshTableView()
        }
    }

    func removeViewModelListeners() {
        insightsChangeReceipt = nil
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [ViewsVisitorsRow.self,
                GrowAudienceRow.self,
                CustomizeInsightsRow.self,
                LatestPostSummaryRow.self,
                TwoColumnStatsRow.self,
                PostingActivityRow.self,
                TabbedTotalsStatsRow.self,
                TopTotalsInsightStatsRow.self,
                MostPopularTimeInsightStatsRow.self,
                TotalInsightStatsRow.self,
                AddInsightRow.self,
                TableFooterRow.self,
                StatsErrorRow.self,
                StatsGhostGrowAudienceImmutableRow.self,
                StatsGhostChartImmutableRow.self,
                StatsGhostTwoColumnImmutableRow.self,
                StatsGhostTopImmutableRow.self,
                StatsGhostTabbedImmutableRow.self,
                StatsGhostPostingActivitiesImmutableRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()

        if viewModel.fetchingFailed() {
            displayFailureViewIfNecessary()
        }

        refreshControl.endRefreshing()
    }

    @objc func refreshData() {
        guard !insightsToShow.isEmpty else {
            refreshControl.endRefreshing()
            return
        }

        refreshControl.beginRefreshing()
        clearExpandedRows()
        refreshInsights(forceRefresh: true)
        hideNoResults()
    }

    func applyTableUpdates() {
        tableView.performBatchUpdates({
        })
    }

    func clearExpandedRows() {
        StatsDataHelper.clearExpandedInsights()
    }

    func updateView() {
        viewModel?.updateInsightsToShow(insights: insightsToShow)
        refreshTableView()
        displayEmptyViewIfNecessary()
    }

    func loadPinnedCards() {
        let viewsCount = insightsStore.getAllTimeStats()?.viewsCount
        switch pinnedItemStore?.itemToDisplay(for: viewsCount ?? 0) {
        case .none:
            insightsToShow = insightsToShow.filter { $0 != .growAudience && $0 != .customize }
        case .some(let item):
            switch item {
            case let hintType as GrowAudienceCell.HintType where !insightsToShow.contains(.growAudience):
                insightsToShow = insightsToShow.filter { $0 != .customize }
                insightsToShow.insert(.growAudience, at: 0)

                // Work around to make sure nudge shown is tracked only once
                if viewsCount != nil {
                    trackNudgeShown(for: hintType)
                }
            case InsightType.customize where !insightsToShow.contains(.customize):
                insightsToShow = insightsToShow.filter { $0 != .growAudience }
            default:
                break
            }
        }
    }

    // MARK: - Customize Card Management

    func dismissCustomizeCard() {
        let item = InsightType.customize
        insightsToShow = insightsToShow.filter { $0 != item }
        pinnedItemStore?.markPinnedItemAsHidden(item)
    }

    // MARK: - Grow Audience Card Management

    func dismissGrowAudienceCard(_ hintType: GrowAudienceCell.HintType) {
        guard let item = pinnedItemStore?.currentItem as? GrowAudienceCell.HintType else {
            return
        }

        insightsToShow = insightsToShow.filter { $0 != .growAudience }

        guard item == hintType else {
            return
        }
        pinnedItemStore?.markPinnedItemAsHidden(item)
        trackNudgeDismissed(for: item)
    }

    func refreshGrowAudienceCardIfNecessary() {
        guard let count = insightsStore.getAllTimeStats()?.viewsCount,
              count != self.currentViewCount else {
                  return
              }

        currentViewCount = count
        loadPinnedCards()
        updateView()
    }

    // MARK: - Insights Management

    func moveInsightUp(_ insight: InsightType) {
        guard canMoveInsightUp(insight) else {
            return
        }

        WPAnalytics.track(.statsItemTappedInsightMoveUp)
        moveInsight(insight, by: -1)
    }

    func moveInsightDown(_ insight: InsightType) {
        guard canMoveInsightDown(insight) else {
            return
        }

        WPAnalytics.track(.statsItemTappedInsightMoveDown)
        moveInsight(insight, by: 1)
    }

    func removeInsight(_ insight: InsightType) {
        WPAnalytics.track(.statsItemTappedInsightRemove, withProperties: ["insight": insight.statSection?.title ?? ""])

        insightsToShow = insightsToShow.filter { $0 != insight }
        updateView()
    }

    func moveInsight(_ insight: InsightType, by offset: Int) {
        guard let currentIndex = indexOfInsight(insight) else {
            return
        }

        insightsToShow.remove(at: currentIndex)
        insightsToShow.insert(insight, at: currentIndex + offset)
        updateView()
    }

    func canMoveInsightUp(_ insight: InsightType) -> Bool {
        let isShowingPinnedCard = insightsToShow.contains(.customize) || insightsToShow.contains(.growAudience)

        let minIndex = isShowingPinnedCard ? 1 : 0

        guard let currentIndex = indexOfInsight(insight),
            (currentIndex - 1) >= minIndex else {
                return false
        }

        return true
    }

    func canMoveInsightDown(_ insight: InsightType) -> Bool {
        guard let currentIndex = indexOfInsight(insight),
            (currentIndex + 1) < insightsToShow.endIndex else {
                return false
        }

        return true
    }

    func indexOfInsight(_ insight: InsightType) -> Int? {
        return insightsToShow.firstIndex(of: insight)
    }

    enum ManageInsightConstants {
        static let moveUp = NSLocalizedString("Move up", comment: "Option to move Insight up in the view.")
        static let moveDown = NSLocalizedString("Move down", comment: "Option to move Insight down in the view.")
        static let remove = NSLocalizedString("Remove from insights", comment: "Option to remove Insight from view.")
        static let cancel = NSLocalizedString("Cancel", comment: "Cancel Insight management action sheet.")
    }

    // MARK: - Grow Audience Helpers

    func markCurrentNudgeAsCompleted() {
        viewModel?.markEmptyStatsNudgeAsCompleted()
        insightsToShow = insightsToShow.filter { $0 != .growAudience }
        refreshTableView()
    }
}

// MARK: - SiteStatsInsightsDelegate Methods

extension SiteStatsInsightsTableViewController: SiteStatsInsightsDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: "site_stats_insights")
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func showCreatePost() {
        RootViewCoordinator.sharedPresenter.showPostTab { [weak self] in
            self?.refreshInsights()
        }
    }

    func showShareForPost(postID: NSNumber, fromView: UIView) {
        guard let blogId = SiteStatsInformation.sharedInstance.siteID, let blog = Blog.lookup(withID: blogId, in: mainContext) else {
            DDLogInfo("Failed to get blog with id \(String(describing: SiteStatsInformation.sharedInstance.siteID))")
            return
        }

        let coreDataStack = ContextManager.shared
        let postRepository = PostRepository(coreDataStack: coreDataStack)
        Task { @MainActor in
            do {
                let postObjectID = try await postRepository.getPost(withID: postID, from: .init(blog))
                let apost = try coreDataStack.mainContext.existingObject(with: postObjectID)

                guard let post = apost as? Post else {
                    DDLogInfo("Failed to get post with id \(postID)")
                    return
                }

                let shareController = PostSharingController()
                shareController.sharePost(post, fromView: fromView, inViewController: self)
            } catch {
                DDLogInfo("Error getting post with id \(postID): \(error.localizedDescription)")
            }
        }
    }

    func showPostingActivityDetails() {
        let postingActivityViewModel = PostingActivityViewModel(insightsStore: insightsStore)
        let postingActivityViewController = PostingActivityViewController.loadFromStoryboard { coder in
            return PostingActivityViewController(coder: coder, viewModel: postingActivityViewModel)
        }
        navigationController?.pushViewController(postingActivityViewController, animated: true)
    }

    func tabbedTotalsCellUpdated() {
        applyTableUpdates()
    }

    func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool) {
        if didSelectRow {
            applyTableUpdates()
        }
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allInsights.contains(statSection) else {
            return
        }

        removeViewModelListeners()

        // When displaying Annual details, start from the most recent year available.
        var selectedDate: Date?
        if statSection == .insightsAnnualSiteStats,
            let year = viewModel?.annualInsightsYear() {
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: StatsDataHelper.currentDateForSite())
            dateComponents.year = year
            selectedDate = Calendar.current.date(from: dateComponents)
        }

        switch statSection {
        case .insightsViewsVisitors, .insightsFollowerTotals, .insightsLikesTotals, .insightsCommentsTotals:
            segueToInsightsDetails(statSection: statSection, selectedDate: selectedDate)
        default:
            segueToDetails(statSection: statSection, selectedDate: selectedDate)
        }
    }

    func segueToInsightsDetails(statSection: StatSection, selectedDate: Date?) {
        let detailTableViewController = SiteStatsInsightsDetailsTableViewController()
        detailTableViewController.configure(statSection: statSection, selectedDate: selectedDate)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func segueToDetails(statSection: StatSection, selectedDate: Date?) {
        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection, selectedDate: selectedDate)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        removeViewModelListeners()

        let postStatsTableViewController = PostStatsTableViewController.withJPBannerForBlog(postID: postID,
                                                                                            postTitle: postTitle,
                                                                                            postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    func customizeDismissButtonTapped() {
        dismissCustomizeCard()
        updateView()
    }

    func customizeTryButtonTapped() {
        showAddInsightView()
    }

    func growAudienceDismissButtonTapped(_ hintType: GrowAudienceCell.HintType) {
        dismissGrowAudienceCard(hintType)
        updateView()
    }

    func growAudienceEnablePostSharingButtonTapped() {
        guard let blogId = SiteStatsInformation.sharedInstance.siteID,
              let blog = Blog.lookup(withID: blogId, in: mainContext) else {
            DDLogInfo("Failed to get blog with id \(String(describing: SiteStatsInformation.sharedInstance.siteID))")
            return
        }

        guard let sharingVC = SharingViewController(blog: blog, delegate: self) else {
            return
        }

        let navigationController = UINavigationController(rootViewController: sharingVC)
        present(navigationController, animated: true)

        applyTableUpdates()

        trackNudgeEvent(.statsPublicizeNudgeTapped)
    }

    func growAudienceBloggingRemindersButtonTapped() {
        guard let blogId = SiteStatsInformation.sharedInstance.siteID,
              let blog = Blog.lookup(withID: blogId, in: mainContext) else {
            DDLogInfo("Failed to get blog with id \(String(describing: SiteStatsInformation.sharedInstance.siteID))")
            return
        }

        BloggingRemindersFlow.present(from: self,
                                      for: blog,
                                      source: .statsInsights,
                                      delegate: self)

        applyTableUpdates()

        trackNudgeEvent(.statsBloggingRemindersNudgeTapped)
    }

    func growAudienceReaderDiscoverButtonTapped() {
        guard let vc = viewModel?.followTopicsViewController else {
            return
        }
        vc.spotlightIsShown = true
        vc.readerDiscoverFlowDelegate = self
        vc.didSaveInterests = { [weak self] interests in
            guard let self = self else {
                return
            }
            self.dismiss(animated: true)
            guard !interests.isEmpty else {
                return
            }

            self.navigationController?.popToRootViewController(animated: false)
            RootViewCoordinator.sharedPresenter.showReaderTab()
            if let vc = RootViewCoordinator.sharedPresenter.readerTabViewController {
                vc.presentDiscoverTab()
            }
        }

        let nc = UINavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        present(nc, animated: true) { [weak self] in
            let text = NSLocalizedString("Follow topics you're interested in and we'll find some blogs you might like.", comment: "Guide for users to follow topics.")
            self?.displayNotice(title: text)
        }

        trackNudgeEvent(.statsReaderDiscoverNudgeTapped)
    }

    func showAddInsight() {
        showAddInsightView()
    }

    func addInsightSelected(_ insight: StatSection) {
        guard let insightType = insight.insightType,
            !insightsToShow.contains(insightType) else {
                return
        }

        WPAnalytics.track(.statsItemSelectedAddInsight, withProperties: ["insight": insight.title])
        insightsToShow.append(insightType)
        refreshInsights(forceRefresh: true)
        updateView()
        scrollToNewCard()
    }

    func addInsightDismissed() {
        guard viewNeedsUpdating else {
            return
        }

        updateView()
        viewNeedsUpdating = false
    }

    func scrollToNewCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            let lastSection = max(self.tableView.numberOfSections - 1, 0)

            // newly added card will be penultimate row, above the 'Add Stats Card' row
            let newCardRow = max(self.tableView.numberOfRows(inSection: lastSection) - 2, 0)

            self.tableView.scrollToRow(at: IndexPath(row: newCardRow, section: lastSection), at: .middle, animated: true)
        }
    }

    func manageInsightSelected(_ insight: StatSection, fromButton: UIButton) {

        guard let insightType = insight.insightType else {
            DDLogDebug("manageInsightSelected: unknown insightType for statSection: \(insight.title).")
            return
        }

        WPAnalytics.track(.statsItemTappedManageInsight)

        let alert = UIAlertController(title: insight.title,
                                      message: nil,
                                      preferredStyle: .actionSheet)

        if canMoveInsightUp(insightType) {
            alert.addDefaultActionWithTitle(ManageInsightConstants.moveUp) { [weak self] _ in
                self?.moveInsightUp(insightType)
            }
        }

        if canMoveInsightDown(insightType) {
            alert.addDefaultActionWithTitle(ManageInsightConstants.moveDown) { [weak self] _ in
                self?.moveInsightDown(insightType)
            }
        }

        alert.addDefaultActionWithTitle(ManageInsightConstants.remove) { [weak self] _ in
            self?.removeInsight(insightType)
        }

        alert.addCancelActionWithTitle(ManageInsightConstants.cancel)

        alert.popoverPresentationController?.sourceView = fromButton
        present(alert, animated: true)
    }
}

// MARK: - StatsInsightsManagementDelegate

extension SiteStatsInsightsTableViewController: StatsInsightsManagementDelegate {
    func userUpdatedActiveInsights(_ insights: [StatSection]) {
        let insightTypes = insights.compactMap({ $0.insightType })

        guard insightTypes.count == insights.count else {
            return
        }

        insightsToShow = insightTypes
        refreshInsights(forceRefresh: true)
        updateView()
    }
}

// MARK: - ViewsVisitorsDelegate

extension SiteStatsInsightsTableViewController: StatsInsightsViewsAndVisitorsDelegate {
    func viewsAndVisitorsSegmendChanged(to selectedSegmentIndex: Int) {
        if let selectedSegment = StatsSegmentedControlData.Segment(rawValue: selectedSegmentIndex) {
            viewModel?.updateViewsAndVisitorsSegment(selectedSegment)
            refreshTableView()
        }
    }
}

// MARK: - Presentation delegate

extension SiteStatsInsightsTableViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let navigationController = presentationController.presentedViewController as? UINavigationController,
        let controller = navigationController.topViewController as? InsightsManagementViewController else {
            return
        }

        controller.handleDismissViaGesture(from: self)
    }
}

// MARK: - SharingViewControllerDelegate

extension SiteStatsInsightsTableViewController: SharingViewControllerDelegate {
    func didChangePublicizeServices() {
        markCurrentNudgeAsCompleted()
        trackNudgeEvent(.statsPublicizeNudgeCompleted)
    }
}

// MARK: - BloggingRemindersFlowDelegate

extension SiteStatsInsightsTableViewController: BloggingRemindersFlowDelegate {
    func didSetUpBloggingReminders() {
        markCurrentNudgeAsCompleted()
        trackNudgeEvent(.statsBloggingRemindersNudgeCompleted)
    }
}

// MARK: - ReaderDiscoverFlowDelegate

extension SiteStatsInsightsTableViewController: ReaderDiscoverFlowDelegate {
    func didCompleteReaderDiscoverFlow() {
        markCurrentNudgeAsCompleted()
        trackNudgeEvent(.statsReaderDiscoverNudgeCompleted)
    }
}

// MARK: - No Results Handling

extension SiteStatsInsightsTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        showAddInsightView()
    }
}

extension SiteStatsInsightsTableViewController: NoResultsViewHost {

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

    private func displayEmptyViewIfNecessary() {
        guard insightsToShow.isEmpty else {
            displayingEmptyView = false
            hideNoResults()
            return
        }

        displayingEmptyView = true
        configureAndDisplayNoResults(on: tableView,
                                     title: NoResultConstants.noInsightsTitle,
                                     subtitle: NoResultConstants.noInsightsSubtitle,
                                     buttonTitle: NoResultConstants.manageInsightsButtonTitle,
                                     image: "wp-illustration-stats-outline") { [weak self] noResults in
                                        noResults.delegate = self
        }
    }

    private enum NoResultConstants {
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
        static let errorSubtitle = NSLocalizedString("There was a problem loading your data, refresh your page to try again.", comment: "The loading view subtitle displayed when an error occurred")
        static let refreshButtonTitle = NSLocalizedString("Refresh", comment: "The loading view button title displayed when an error occurred")
        static let noInsightsTitle = NSLocalizedString("No insights added yet", comment: "Title displayed when the user has removed all Insights from display.")
        static let noInsightsSubtitle = NSLocalizedString("Only see the most relevant stats. Add insights to fit your needs.", comment: "Subtitle displayed when the user has removed all Insights from display.")
        static let manageInsightsButtonTitle = NSLocalizedString("Add stats card", comment: "Button title displayed when the user has removed all Insights from display.")
    }
}

// MARK: - Tracks Support

private extension SiteStatsInsightsTableViewController {

    func trackNudgeEvent(_ event: WPAnalyticsEvent) {
        if let blogId = SiteStatsInformation.sharedInstance.siteID,
           let blog = Blog.lookup(withID: blogId, in: mainContext) {
            WPAnalytics.track(event, properties: [:], blog: blog)
        } else {
            WPAnalytics.track(event)
        }
    }

    func trackNudgeShown(for hintType: GrowAudienceCell.HintType) {
        switch hintType {
        case .social:
            trackNudgeEvent(.statsPublicizeNudgeShown)
        case .bloggingReminders:
            trackNudgeEvent(.statsBloggingRemindersNudgeShown)
        case .readerDiscover:
            trackNudgeEvent(.statsReaderDiscoverNudgeShown)
        }
    }

    func trackNudgeDismissed(for hintType: GrowAudienceCell.HintType) {
        switch hintType {
        case .social:
            trackNudgeEvent(.statsPublicizeNudgeDismissed)
        case .bloggingReminders:
            trackNudgeEvent(.statsBloggingRemindersNudgeDismissed)
        case .readerDiscover:
            trackNudgeEvent(.statsReaderDiscoverNudgeDismissed)
        }
    }
}

// MARK: Jetpack powered banner

private extension SiteStatsInsightsTableViewController {

    func sendScrollEventsToBanner() {
        if let bannerView = bannerView {
            analyticsTracker.addTranslationObserver(bannerView)
        }
    }
}
