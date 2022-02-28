import Foundation
import CocoaLumberjack
import SVProgressHUD
import WordPressShared
import WordPressFlux

struct ActivityListConfiguration {
    /// An identifier of the View Controller
    let identifier: String

    /// The title of the View Controller
    let title: String

    /// The title for when loading activities
    let loadingTitle: String

    /// Title for when there are no activities
    let noActivitiesTitle: String

    /// Subtitle for when there are no activities
    let noActivitiesSubtitle: String

    /// Title for when there are no activities for the selected filter
    let noMatchingTitle: String

    /// Subtitle for when there are no activities for the selected filter
    let noMatchingSubtitle: String

    /// Event to be fired when the date range button is tapped
    let filterbarRangeButtonTapped: WPAnalyticsEvent

    /// Event to be fired when a date range is selected
    let filterbarSelectRange: WPAnalyticsEvent

    /// Event to be fired when the range date reset button is tapped
    let filterbarResetRange: WPAnalyticsEvent

    /// The number of items to be requested for each page
    let numberOfItemsPerPage: Int
}

/// ActivityListViewController is used as a base ViewController for
/// Jetpack's Activity Log and Backup
///
class BaseActivityListViewController: UIViewController, TableViewContainer, ImmuTablePresenter {
    let site: JetpackSiteRef
    let store: ActivityStore
    let configuration: ActivityListConfiguration
    let isFreeWPCom: Bool

    var changeReceipt: Receipt?
    var isUserTriggeredRefresh: Bool = false

    let containerStackView = UIStackView()

    let filterView = FilterBarView()
    let dateFilterChip = FilterChipButton()
    let activityTypeFilterChip = FilterChipButton()

    var tableView: UITableView = UITableView()
    let refreshControl = UIRefreshControl()

    let numberOfItemsPerPage = 100

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self, with: self)
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
        return spinner
    }()

    var viewModel: ActivityListViewModel
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 62
    }

    // MARK: - GUI

    fileprivate var noResultsViewController: NoResultsViewController?

    // MARK: - Constructors

    init(site: JetpackSiteRef,
         store: ActivityStore,
         isFreeWPCom: Bool = false) {
        fatalError("A configuration struct needs to be provided")
    }

    init(site: JetpackSiteRef,
         store: ActivityStore,
         configuration: ActivityListConfiguration,
         isFreeWPCom: Bool = false) {
        self.site = site
        self.store = store
        self.isFreeWPCom = isFreeWPCom
        self.configuration = configuration
        self.viewModel = ActivityListViewModel(site: site, store: store, configuration: configuration)

        super.init(nibName: nil, bundle: nil)

        self.changeReceipt = viewModel.onChange { [weak self] in
            self?.refreshModel()
        }

        view.addSubview(containerStackView)
        containerStackView.axis = .vertical

        if site.shouldShowActivityLogFilter() {
            setupFilterBar()
        }

        containerStackView.addArrangedSubview(tableView)

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(containerStackView)

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(userRefresh), for: .valueChanged)

        title = configuration.title
    }

    @objc private func showCalendar() {
        let calendarViewController = CalendarViewController(startDate: viewModel.after, endDate: viewModel.before)
        calendarViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: calendarViewController)
        present(navigationController, animated: true, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let siteRef = JetpackSiteRef(blog: blog) else {
            return nil
        }


        let isFreeWPCom = blog.isHostedAtWPcom && !blog.hasPaidPlan
        self.init(site: siteRef, store: StoreContainer.shared.activity, isFreeWPCom: isFreeWPCom)
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshModel()

        tableView.estimatedRowHeight = Constants.estimatedRowHeight

        WPStyleGuide.configureColors(view: view, tableView: tableView)

        let nib = UINib(nibName: ActivityListSectionHeaderView.identifier, bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: ActivityListSectionHeaderView.identifier)
        ImmuTable.registerRows([ActivityListRow.self, RewindStatusRow.self], tableView: tableView)

        tableView.tableFooterView = spinner
        tableView.tableFooterView?.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }

    @objc func userRefresh() {
        isUserTriggeredRefresh = true
        viewModel.refresh(after: viewModel.after, before: viewModel.before, group: viewModel.selectedGroups)
    }

    func refreshModel() {
        updateHeader()
        handler.viewModel = viewModel.tableViewModel(presenter: self)
        updateRefreshControl()
        updateNoResults()
        updateFilters()
    }

    private func updateHeader() {
        tableView.tableHeaderView = viewModel.backupDownloadHeader()

        guard let tableHeaderView = tableView.tableHeaderView else {
            return
        }

        tableHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableHeaderView.topAnchor.constraint(equalTo: tableView.topAnchor),
            tableHeaderView.safeLeadingAnchor.constraint(equalTo: tableView.safeLeadingAnchor),
            tableHeaderView.safeTrailingAnchor.constraint(equalTo: tableView.safeTrailingAnchor)
        ])
        tableView.tableHeaderView?.layoutIfNeeded()
    }

    private func updateRefreshControl() {
        switch (viewModel.refreshing, refreshControl.isRefreshing) {
        case (true, false):
            if isUserTriggeredRefresh {
                refreshControl.beginRefreshing()
                isUserTriggeredRefresh = false
            } else if tableView.numberOfSections > 0 {
                tableView.tableFooterView?.isHidden = false
            }
        case (false, true):
            refreshControl.endRefreshing()
        default:
            tableView.tableFooterView?.isHidden = true
            break
        }
    }

    private func updateFilters() {
        viewModel.dateFilterIsActive ? dateFilterChip.enableResetButton() : dateFilterChip.disableResetButton()
        dateFilterChip.title = viewModel.dateRangeDescription()

        viewModel.groupFilterIsActive ? activityTypeFilterChip.enableResetButton() : activityTypeFilterChip.disableResetButton()
        activityTypeFilterChip.title = viewModel.activityTypeDescription()
    }

    private func setupFilterBar() {
        containerStackView.addArrangedSubview(filterView)

        filterView.add(button: dateFilterChip)
        filterView.add(button: activityTypeFilterChip)

        setupDateFilter()
        setupActivityTypeFilter()
    }

    private func setupDateFilter() {
        dateFilterChip.resetButton.accessibilityLabel = NSLocalizedString("Reset Date Range filter", comment: "Accessibility label for the reset date range button")

        dateFilterChip.tapped = { [unowned self] in
            WPAnalytics.track(self.configuration.filterbarRangeButtonTapped)
            self.showCalendar()
        }

        dateFilterChip.resetTapped = { [unowned self] in
            WPAnalytics.track(self.configuration.filterbarResetRange)
            self.viewModel.removeDateFilter()
            self.dateFilterChip.disableResetButton()
        }
    }

    private func setupActivityTypeFilter() {
        activityTypeFilterChip.resetButton.accessibilityLabel = NSLocalizedString("Reset Activity Type filter", comment: "Accessibility label for the reset activity type button")

        activityTypeFilterChip.tapped = { [weak self] in
            guard let self = self else {
                return
            }

            WPAnalytics.track(.activitylogFilterbarTypeButtonTapped)

            let activityTypeSelectorViewController = ActivityTypeSelectorViewController(
                viewModel: self.viewModel
            )
            activityTypeSelectorViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: activityTypeSelectorViewController)
            self.present(navigationController, animated: true, completion: nil)
        }

        activityTypeFilterChip.resetTapped = { [weak self] in
            WPAnalytics.track(.activitylogFilterbarResetType)
            self?.viewModel.removeGroupFilter()
            self?.activityTypeFilterChip.disableResetButton()
        }
    }

}

extension BaseActivityListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        handler.tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        handler.tableView(tableView, cellForRowAt: indexPath)
    }
}

// MARK: - UITableViewDelegate

extension BaseActivityListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let isLastSection = handler.viewModel.sections.count == section + 1

        guard isFreeWPCom, isLastSection, let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ActivityListSectionHeaderView.identifier) as? ActivityListSectionHeaderView else {
            return nil
        }

        cell.separator.isHidden = true
        cell.titleLabel.text = NSLocalizedString("Since you're on a free plan, you'll see limited events in your Activity Log.", comment: "Text displayed as a footer of a table view with Activities when user is on a free plan")

        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let isLastSection = handler.viewModel.sections.count == section + 1

        guard isFreeWPCom, isLastSection else {
            return 0.0
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ActivityListSectionHeaderView.identifier) as? ActivityListSectionHeaderView else {
            return nil
        }

        cell.titleLabel.text = handler.tableView(tableView, titleForHeaderInSection: section)?.localizedUppercase

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ActivityListSectionHeaderView.height
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let row = handler.viewModel.rowAtIndexPath(indexPath) as? ActivityListRow else {
            return false
        }

        return row.activity.isRewindable
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let shouldLoadMore = offsetY > contentHeight - (2 * scrollView.frame.size.height) && viewModel.hasMore

        if shouldLoadMore {
            viewModel.loadMore()
        }
    }

}

// MARK: - NoResultsViewControllerDelegate

extension BaseActivityListViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}

// MARK: - ActivityPresenter

extension BaseActivityListViewController: ActivityPresenter {

    func presentDetailsFor(activity: FormattableActivity) {
        let detailVC = ActivityDetailViewController.loadFromStoryboard()

        detailVC.site = site
        detailVC.rewindStatus = store.state.rewindStatus[site]
        detailVC.formattableActivity = activity
        detailVC.presenter = self

        self.navigationController?.pushViewController(detailVC, animated: true)
    }

    func presentBackupOrRestoreFor(activity: Activity, from sender: UIButton) {
        let rewindStatus = store.state.rewindStatus[site]

        let title = rewindStatus?.isMultisite() == true ? RewindStatus.Strings.multisiteNotAvailable : nil

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        if rewindStatus?.state == .active {
            let restoreTitle = NSLocalizedString("Restore", comment: "Title displayed for restore action.")

            let restoreOptionsVC = JetpackRestoreOptionsViewController(site: site,
                                                                       activity: activity,
                                                                       isAwaitingCredentials: store.isAwaitingCredentials(site: site))
            restoreOptionsVC.restoreStatusDelegate = self
            restoreOptionsVC.presentedFrom = configuration.identifier
            alertController.addDefaultActionWithTitle(restoreTitle, handler: { _ in
                self.present(UINavigationController(rootViewController: restoreOptionsVC), animated: true)
            })
        }

        let backupTitle = NSLocalizedString("Download backup", comment: "Title displayed for download backup action.")
        let backupOptionsVC = JetpackBackupOptionsViewController(site: site, activity: activity)
        backupOptionsVC.backupStatusDelegate = self
        backupOptionsVC.presentedFrom = configuration.identifier
        alertController.addDefaultActionWithTitle(backupTitle, handler: { _ in
            self.present(UINavigationController(rootViewController: backupOptionsVC), animated: true)
        })

        let cancelTitle = NSLocalizedString("Cancel", comment: "Title for cancel action. Dismisses the action sheet.")
        alertController.addCancelActionWithTitle(cancelTitle)

        if let presentationController = alertController.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = sender
            presentationController.sourceRect = sender.bounds
        }

        self.present(alertController, animated: true, completion: nil)
    }

    func presentRestoreFor(activity: Activity, from: String? = nil) {
        guard activity.isRewindable, activity.rewindID != nil else {
            return
        }

        let restoreOptionsVC = JetpackRestoreOptionsViewController(site: site,
                                                                   activity: activity,
                                                                   isAwaitingCredentials: store.isAwaitingCredentials(site: site))

        restoreOptionsVC.restoreStatusDelegate = self
        restoreOptionsVC.presentedFrom = from ?? configuration.identifier
        let navigationVC = UINavigationController(rootViewController: restoreOptionsVC)
        self.present(navigationVC, animated: true)
    }

    func presentBackupFor(activity: Activity, from: String? = nil) {
        let backupOptionsVC = JetpackBackupOptionsViewController(site: site, activity: activity)
        backupOptionsVC.backupStatusDelegate = self
        backupOptionsVC.presentedFrom = from ?? configuration.identifier
        let navigationVC = UINavigationController(rootViewController: backupOptionsVC)
        self.present(navigationVC, animated: true)
    }
}

// MARK: - Restores handling

extension BaseActivityListViewController {

    fileprivate func restoreSiteToRewindID(_ rewindID: String) {
        navigationController?.popToViewController(self, animated: true)
        store.actionDispatcher.dispatch(ActivityAction.rewind(site: site, rewindID: rewindID))
    }
}

// MARK: - NoResults Handling

private extension BaseActivityListViewController {

    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel() {
            showNoResults(noResultsViewModel)
        } else {
            noResultsViewController?.view.isHidden = true
        }
    }

    func showNoResults(_ viewModel: NoResultsViewController.Model) {
        if noResultsViewController == nil {
            noResultsViewController = NoResultsViewController.controller()
            noResultsViewController?.delegate = self

            guard let noResultsViewController = noResultsViewController else {
                return
            }

            if noResultsViewController.view.superview != tableView {
                tableView.addSubview(withFadeAnimation: noResultsViewController.view)
            }

            addChild(noResultsViewController)

            noResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }

        noResultsViewController?.bindViewModel(viewModel)
        noResultsViewController?.didMove(toParent: self)
        tableView.pinSubviewToSafeArea(noResultsViewController!.view)
        noResultsViewController?.view.isHidden = false
    }

}

// MARK: - Restore Status Handling

extension BaseActivityListViewController: JetpackRestoreStatusViewControllerDelegate {

    func didFinishViewing(_ controller: JetpackRestoreStatusViewController) {
        controller.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else {
                return
            }
            self.store.fetchRewindStatus(site: self.site)
        })
    }
}

// MARK: - Restore Status Handling

extension BaseActivityListViewController: JetpackBackupStatusViewControllerDelegate {

    func didFinishViewing() {
        viewModel.refresh()
    }
}

// MARK: - Calendar Handling
extension BaseActivityListViewController: CalendarViewControllerDelegate {
    func didCancel(calendar: CalendarViewController) {
        calendar.dismiss(animated: true, completion: nil)
    }

    func didSelect(calendar: CalendarViewController, startDate: Date?, endDate: Date?) {
        guard startDate != viewModel.after || endDate != viewModel.before else {
            calendar.dismiss(animated: true, completion: nil)
            return
        }

        trackSelectedRange(startDate: startDate, endDate: endDate)

        viewModel.refresh(after: startDate, before: endDate, group: viewModel.selectedGroups)
        calendar.dismiss(animated: true, completion: nil)
    }

    private func trackSelectedRange(startDate: Date?, endDate: Date?) {
        guard let startDate = startDate else {
            if viewModel.after != nil || viewModel.before != nil {
                WPAnalytics.track(configuration.filterbarResetRange)
            }

            return
        }

        var duration: Int // Number of selected days
        var distance: Int // Distance from the startDate to today (in days)

        if let endDate = endDate {
            duration = Int((endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate) / Double(24 * 60 * 60)) + 1
        } else {
            duration = 1
        }

        distance = Int((Date().timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate) / Double(24 * 60 * 60))

        WPAnalytics.track(configuration.filterbarSelectRange, properties: ["duration": duration, "distance": distance])
    }
}

// MARK: - Activity type filter handling
extension BaseActivityListViewController: ActivityTypeSelectorDelegate {
    func didCancel(selectorViewController: ActivityTypeSelectorViewController) {
        selectorViewController.dismiss(animated: true, completion: nil)
    }

    func didSelect(selectorViewController: ActivityTypeSelectorViewController, groups: [ActivityGroup]) {
        guard groups != viewModel.selectedGroups else {
            selectorViewController.dismiss(animated: true, completion: nil)
            return
        }

        trackSelectedGroups(groups)

        viewModel.refresh(after: viewModel.after, before: viewModel.before, group: groups)
        selectorViewController.dismiss(animated: true, completion: nil)
    }

    private func trackSelectedGroups(_ selectedGroups: [ActivityGroup]) {
        if !viewModel.selectedGroups.isEmpty && selectedGroups.isEmpty {
            WPAnalytics.track(.activitylogFilterbarResetType)
        } else {
            let totalActivitiesSelected = selectedGroups.map { $0.count }.reduce(0, +)
            var selectTypeProperties: [AnyHashable: Any] = [:]
            selectedGroups.forEach { selectTypeProperties["group_\($0.key)"] = true }
            selectTypeProperties["num_groups_selected"] = selectedGroups.count
            selectTypeProperties["num_total_activities_selected"] = totalActivitiesSelected
            WPAnalytics.track(.activitylogFilterbarSelectType, properties: selectTypeProperties)
        }
    }
}
