import Foundation
import CocoaLumberjack
import SVProgressHUD
import WordPressShared
import WordPressFlux

class ActivityListViewController: UITableViewController, ImmuTablePresenter {

    let site: JetpackSiteRef

    let store: ActivityStore
    let activitiesReceipt: Receipt
    let restoreStatusReceipt: Receipt

    var actionsReceipt: Receipt?
    var changeReceipt: Receipt?

    var lastRewindStatus: RewindStatus?
    // The way our API works, if there was a restore event "recently" (for some undefined value of "recently",
    // on the order of magnitude of ~30 minutes or so), it'll be reported back by the API.
    // But if the restore has finished a good while back (e.g. there's also an event in the AL telling us
    // about the restore happening) we don't neccesarily want to display that redundant info to the users.
    // Hence this somewhat dumb hack — if we've gotten updates about a RewindStatus before (which means we have displayed a progress bar),
    // we're gonna show users "hey, your rewind finished!". But if the only thing we know the restore is
    // that it has finished in a recent past, we don't do anything special.

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    fileprivate var viewModel: ActivityListViewModel = .loading {
        didSet {
            refreshModel()
        }
    }

    private enum Constants {
        static let estimatedRowHeight: CGFloat = 62
    }

    // MARK: - GUI

    fileprivate var noResultsViewController: NoResultsViewController?

    // MARK: - Constructors

    init(site: JetpackSiteRef, store: ActivityStore) {
        self.site = site
        self.store = store

        self.activitiesReceipt = store.query(.activities(site: site))
        self.restoreStatusReceipt = store.query(.restoreStatus(site: site))

        super.init(style: .plain)

        self.changeReceipt = store.onChange { [weak self] in
            self?.updateViewModel()
        }

        self.actionsReceipt = ActionDispatcher.global.subscribe { [weak self] action in
            switch action {
            case ActivityAction.rewindStarted(let site, _):
                guard site == self?.site else { return }
                self?.showRestoringMessage(0)
            case ActivityAction.rewindFinished(let site, _):
                guard site == self?.site else { return }
                self?.restoreCompleted()
            case ActivityAction.rewindFailed(let site, _), ActivityAction.rewindRequestFailed(let site, _):
                guard site == self?.site else { return }
                self?.restoreFailed()
            case ActivityAction.rewindStatusUpdateTimedOut(let site):
                guard site == self?.site else { return }
                self?.restoreTimedout()
            case ActivityAction.rewindStatusUpdated(let site, let status):
                guard site == self?.site, let restore = status.restore, (restore.status == .running || restore.status == .queued) else {
                    return
                }

                self?.lastRewindStatus = status
                self?.showRestoringMessage(Float(restore.progress) / 100.0)
            default: return
            }
        }

        title = NSLocalizedString("Activity", comment: "Title for the activity list")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let siteRef = JetpackSiteRef(blog: blog) else {
            return nil
        }


        self.init(site: siteRef, store: StoreContainer.shared.activity)
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

    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }

    func updateViewModel() {
        guard let activities = store.getActivities(site: site) else {
            self.viewModel = .error
            return
        }

        self.viewModel = .ready(activities)
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
        store.actionDispatcher.dispatch(ActivityAction.rewind(site: site, rewindID: rewindID))
    }

    fileprivate func showErrorRestoringMessage() {
        SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Unable to restore your site, please try again later or contact support.",
                                                                         comment: "Text displayed when a site restore fails."))
        tableView.isUserInteractionEnabled = true
    }

    fileprivate func showRestoringMessage(_ progress: Float = 0) {
        tableView.isUserInteractionEnabled = false
        SVProgressHUD.showProgress(progress, status: NSLocalizedString("Restoring ...",
                                                                       comment: "Text displayed in HUD while a site is being restored."))
    }

    fileprivate func showErrorFetchingRestoreStatus() {
        SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Your restore is taking longer than usual, please check again in a few minutes.",
                                                                         comment: "Text displayed when a site restore takes too long."))
        tableView.isUserInteractionEnabled = true
    }

    fileprivate func restoreCompleted() {
        guard self.lastRewindStatus != nil else {
            return
        }

        SVProgressHUD.showDismissibleSuccess(withStatus: NSLocalizedString("Restore completed",
                                                                           comment: "Text displayed in HUD when the site restore is completed."))
        tableView.isUserInteractionEnabled = true
        refreshModel()
    }

    fileprivate func restoreFailed() {
        guard self.lastRewindStatus != nil else {
            return
        }

        showErrorRestoringMessage()
    }

    fileprivate func restoreTimedout() {
        guard self.lastRewindStatus != nil else {
            return
        }

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
