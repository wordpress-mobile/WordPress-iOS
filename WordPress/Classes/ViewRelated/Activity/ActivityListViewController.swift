import Foundation
import CocoaLumberjack
import SVProgressHUD
import WordPressShared

class ActivityListViewController: UITableViewController, ImmuTablePresenter {

    let siteID: Int
    let service: ActivityServiceRemote

    enum Constants {
        /// Sequence of increasing delays to apply to the fetch restore status mechanism (in seconds)
        ///
        static let delaySequence = [1, 5]
        static let maxRetries = 12
        static let estimatedRowHeight: CGFloat = 62
    }
    fileprivate var delay = IncrementalDelay(Constants.delaySequence)
    fileprivate var delayedRetry: DispatchDelayedAction?
    fileprivate var delayedRetryAttempt: Int = 0

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    fileprivate var viewModel: ActivityListViewModel = .loading {
        didSet {
            refreshModel()
        }
    }

    // MARK: - GUI

    fileprivate var noResultsViewController: NoResultsViewController?

    // MARK: - Constructors

    init(siteID: Int, service: ActivityServiceRemote) {
        self.siteID = siteID
        self.service = service
        super.init(style: .plain)
        title = NSLocalizedString("Activity", comment: "Title for the activity list")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let api = blog.wordPressComRestApi(), let siteID = blog.dotComID?.intValue else {
            return nil
        }

        let service = ActivityServiceRemote(wordPressComRestApi: api)
        self.init(siteID: siteID, service: service)
    }

    deinit {
        delayedRetry?.cancel()
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = Constants.estimatedRowHeight

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        let nib = UINib(nibName: ActivityListSectionHeaderView.identifier, bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: ActivityListSectionHeaderView.identifier)
        ImmuTable.registerRows([ActivityListRow.self], tableView: tableView)
        // Magic to avoid cell separators being displayed while a plain table loads
        tableView.tableFooterView = UIView()

        refreshModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        service.getActivityForSite(siteID, count: 1000, success: { (activities, _) in
            self.viewModel = .ready(activities)
        }, failure: { error in
            DDLogError("Error loading activities: \(error)")
            self.viewModel = .error(String(describing: error))
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }

    func refreshModel() {
        handler.viewModel = viewModel.tableViewModel(presenter: self)
        updateNoResults()
    }

}

// MARK: - UITableViewDelegate

extension ActivityListViewController {

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ActivityListSectionHeaderView.identifier) as? ActivityListSectionHeaderView else {
            return nil
        }

        cell.titleLabel.text = handler.tableView(tableView, titleForHeaderInSection: section)?.localizedUppercase

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ActivityListSectionHeaderView.height
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let row = handler.viewModel.rowAtIndexPath(indexPath) as? ActivityListRow else {
            return false
        }

        return row.activity.isRewindable
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let row = handler.viewModel.rowAtIndexPath(indexPath) as? ActivityListRow, row.activity.isRewindable else {
            return nil
        }

        let rewindAction = UITableViewRowAction(style: .normal,
                                                title: NSLocalizedString("Rewind", comment: "Title displayed when user swipes on a rewind cell"),
                                                handler: { [weak self] _, indexPath in
                                                    self?.presentRewindFor(activity: row.activity)
        })
        rewindAction.backgroundColor = WPStyleGuide.mediumBlue()

        return [rewindAction]
    }

}

// MARK: - NoResultsViewControllerDelegate

extension ActivityListViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}

// MARK: - ActivityRewindPresenter

extension ActivityListViewController: ActivityRewindPresenter {

    func presentRewindFor(activity: Activity) {
        guard activity.isRewindable, let rewindID = activity.rewindID else {
            return
        }

        let title = NSLocalizedString("Rewind Site",
                                      comment: "Title displayed in the Rewind Site alert, should match Calypso")
        let rewindDate = activity.published.mediumStringWithUTCTime()
        let messageFormat = NSLocalizedString("Are you sure you want to rewind your site back to %@?\nThis will remove all content and options created or changed since then.",
                                              comment: "Message displayed in the Rewind Site alert, the placeholder holds a date, should match Calypso.")
        let message = String(format: messageFormat, rewindDate)

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: ""))
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Confirm Rewind",
                                                                        comment: "Confirm Rewind button title"),
                                                      handler: { action in
                                                        self.restoreSiteToRewindID(rewindID)
                                                      })
        self.present(alertController, animated: true, completion: nil)
    }

}
extension ActivityListViewController: ActivityDetailPresenter {

    func presentDetailsFor(activity: Activity) {
        let activityStoryboard = UIStoryboard(name: "Activity", bundle: nil)
        guard let detailVC = activityStoryboard.instantiateViewController(withIdentifier: "ActivityDetailViewController") as? ActivityDetailViewController else {
            return
        }

        detailVC.activity = activity
        detailVC.rewindPresenter = self

        self.navigationController?.pushViewController(detailVC, animated: true)
    }

}

// MARK: - Restores handling

extension ActivityListViewController {

    fileprivate func restoreSiteToRewindID(_ rewindID: String) {
        navigationController?.popToViewController(self, animated: true)
        tableView.isUserInteractionEnabled = false
        service.restoreSite(siteID, rewindID: rewindID, success: { (restoreID) in
            self.showRestoringMessage()
            self.delayedRetryAttempt = 0
            self.checkStatusDelayedForRestoreID(restoreID)
        }) { (error) in
            self.tableView.isUserInteractionEnabled = true
            self.showErrorRestoringMessage()
        }
    }

    fileprivate func checkStatusDelayedForRestoreID(_ restoreID: String) {
        delayedRetryAttempt = delayedRetryAttempt + 1
        guard delayedRetryAttempt < Constants.maxRetries else {
            restoreTimedout()
            return
        }

        service.getRewindStatus(siteID, success: { (rewindStatus) in
            guard let restoreStatus = rewindStatus.restore,
                restoreStatus.id == restoreID else {
                self.delayedRetryForRestoreID(restoreID, showingProgress: 0)
                return
            }

            switch restoreStatus.status {
            case .running, .queued:
                self.delayedRetryForRestoreID(restoreID, showingProgress: restoreStatus.progress)
            case .finished:
                self.restoreCompleted()
            case .fail:
                self.restoreFailed()
            }
        }) { (error) in
            DDLogError("Error checking restore status \(error)")
        }
    }

    fileprivate func delayedRetryForRestoreID(_ restoreID: String, showingProgress progress: Int) {
        self.showRestoringMessage(Float(progress) / 100.0)
        self.delayedRetry = DispatchDelayedAction(delay: .seconds(self.delay.current)) { [weak self] in
            self?.checkStatusDelayedForRestoreID(restoreID)
        }
        self.delay.increment()
    }

    fileprivate func showErrorRestoringMessage() {
        SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Unable to restore your site, please try again later or contact support.",
                                                                         comment: "Text displayed when a site restore fails."))
    }

    fileprivate func showRestoringMessage(_ progress: Float = 0) {
        SVProgressHUD.showProgress(progress, status: NSLocalizedString("Restoring ...",
                                                                       comment: "Text displayed in HUD while a site is being restored."))
    }

    fileprivate func showErrorFetchingRestoreStatus() {
        SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Your restore is taking longer than usual, please check again in a few minutes.",
                                                                         comment: "Text displayed when a site restore takes too long."))
    }

    fileprivate func restoreCompleted() {
        delay.reset()
        tableView.isUserInteractionEnabled = true
        SVProgressHUD.showDismissibleSuccess(withStatus: NSLocalizedString("Restore completed",
                                                                           comment: "Text displayed in HUD when the site restore is completed."))
        refreshModel()
    }

    fileprivate func restoreFailed() {
        delay.reset()
        tableView.isUserInteractionEnabled = true
        showErrorRestoringMessage()
    }

    fileprivate func restoreTimedout() {
        delay.reset()
        tableView.isUserInteractionEnabled = true
        showErrorFetchingRestoreStatus()
    }
}

// MARK: - NoResults Handling

private extension ActivityListViewController {

    func setupNoResultsViewController() {
        let noResultsStoryboard = UIStoryboard(name: "NoResults", bundle: nil)
        guard let noResultsViewController = noResultsStoryboard.instantiateViewController(withIdentifier: "NoResults") as? NoResultsViewController else {
            return
        }

        noResultsViewController.delegate = self
        self.noResultsViewController = noResultsViewController
    }

    func updateNoResults() {
        hideNoResults()
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        }
    }

    func showNoResults(_ viewModel: NoResultsViewController.Model) {

        if noResultsViewController == nil {
            setupNoResultsViewController()
        }

        guard let noResultsViewController = noResultsViewController else {
            return
        }

        noResultsViewController.bindViewModel(viewModel)

        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        addChildViewController(noResultsViewController)
        noResultsViewController.didMove(toParentViewController: self)

    }

    func hideNoResults() {

        guard let noResultsViewController = noResultsViewController else {
            return
        }

        noResultsViewController.view.removeFromSuperview()
        noResultsViewController.removeFromParentViewController()
    }

}
