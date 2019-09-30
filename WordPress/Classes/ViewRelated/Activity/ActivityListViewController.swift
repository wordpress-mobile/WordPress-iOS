import Foundation
import CocoaLumberjack
import SVProgressHUD
import WordPressShared
import WordPressFlux

class ActivityListViewController: UITableViewController, ImmuTablePresenter {

    let site: JetpackSiteRef
    let store: ActivityStore
    let isFreeWPCom: Bool

    var changeReceipt: Receipt?
    var isUserTriggeredRefresh: Bool = false

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    fileprivate var viewModel: ActivityListViewModel
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 62
    }

    // MARK: - GUI

    fileprivate var noResultsViewController: NoResultsViewController?

    // MARK: - Constructors

    init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        self.site = site
        self.store = store
        self.isFreeWPCom = isFreeWPCom
        self.viewModel = ActivityListViewModel(site: site, store: store)

        super.init(style: .plain)

        self.changeReceipt = viewModel.onChange { [weak self] in
            self?.refreshModel()
        }

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(userRefresh), for: .valueChanged)

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
        // Magic to avoid cell separators being displayed while a plain table loads
        tableView.tableFooterView = UIView()

        WPAnalytics.track(.activityLogViewed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }

    @objc func userRefresh() {
        isUserTriggeredRefresh = true
        viewModel.refresh()
    }

    func refreshModel() {
        handler.viewModel = viewModel.tableViewModel(presenter: self)
        updateRefreshControl()
        updateNoResults()
    }

    private func updateRefreshControl() {
        guard let refreshControl = refreshControl else {
            return
        }

        switch (viewModel.refreshing, refreshControl.isRefreshing) {
        case (true, false):
            if isUserTriggeredRefresh {
                refreshControl.beginRefreshing()
                isUserTriggeredRefresh = false
            }
        case (false, true):
            refreshControl.endRefreshing()
        default:
            break
        }
    }

}

// MARK: - UITableViewDelegate

extension ActivityListViewController {

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let isLastSection = handler.viewModel.sections.count == section + 1

        guard isFreeWPCom, isLastSection, let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ActivityListSectionHeaderView.identifier) as? ActivityListSectionHeaderView else {
            return nil
        }

        cell.separator.isHidden = true
        cell.titleLabel.text = NSLocalizedString("Since you're on a free plan, you'll see limited events in your Activity Log.", comment: "Text displayed as a footer of a table view with Activities when user is on a free plan")

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let isLastSection = handler.viewModel.sections.count == section + 1

        guard isFreeWPCom, isLastSection else {
            return 0.0
        }

        return UITableView.automaticDimension
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
        rewindAction.backgroundColor = .primary(.shade40)

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
        let rewindDate = viewModel.mediumDateFormatterWithTime.string(from: activity.published)
        let messageFormat = NSLocalizedString("Are you sure you want to rewind your site back to %@?\nThis will remove all content and options created or changed since then.",
                                              comment: "Message displayed in the Rewind Site alert, the placeholder holds a date, should match Calypso.")
        let message = String(format: messageFormat, rewindDate)

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Verb. A button title."))
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Confirm Rewind",
                                                                        comment: "Confirm Rewind button title"),
                                                      handler: { action in
                                                        self.restoreSiteToRewindID(rewindID)
                                                      })
        self.present(alertController, animated: true)
    }

}
extension ActivityListViewController: ActivityDetailPresenter {

    func presentDetailsFor(activity: FormattableActivity) {
        let activityStoryboard = UIStoryboard(name: "Activity", bundle: nil)
        guard let detailVC = activityStoryboard.instantiateViewController(withIdentifier: "ActivityDetailViewController") as? ActivityDetailViewController else {
            return
        }

        detailVC.site = site
        detailVC.formattableActivity = activity
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
}

// MARK: - NoResults Handling

private extension ActivityListViewController {

    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel() {
            showNoResults(noResultsViewModel)
        } else {
            noResultsViewController?.removeFromView()
        }
    }

    func showNoResults(_ viewModel: NoResultsViewController.Model) {
        if noResultsViewController == nil {
            noResultsViewController = NoResultsViewController.controller()
            noResultsViewController?.delegate = self
        }

        guard let noResultsViewController = noResultsViewController else {
            return
        }

        noResultsViewController.bindViewModel(viewModel)

        if noResultsViewController.view.superview != tableView {
            tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        }

        addChild(noResultsViewController)
        noResultsViewController.didMove(toParent: self)

    }

}
