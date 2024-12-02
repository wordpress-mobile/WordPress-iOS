import UIKit
import WordPressShared

final class PlanListViewController: UITableViewController, ImmuTablePresenter {

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    fileprivate var viewModel: PlanListViewModel = .loading {
        didSet {
            handler.viewModel = viewModel.tableViewModelWithPresenter(self)
            updateNoResults()
        }
    }

    fileprivate var noResultsViewController: NoResultsViewController?

    override init(style: UITableView.Style) {
        super.init(style: .grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        ImmuTable.registerRows([PlanListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModelWithPresenter(self)
        updateNoResults()
        updateViewModel()
        syncPlans()
    }

    func syncPlans() {
        let context = ContextManager.shared.mainContext

        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
            return
        }

        let plansService = PlanService(coreDataStack: ContextManager.shared)
        plansService.getWpcomPlans(account,
                                   success: { [weak self] in
            self?.updateViewModel()

        }, failure: { error in
            DDLogInfo("\(error.debugDescription)")
        })
    }

    func updateViewModel() {
        let contextManager = ContextManager.shared
        let service = PlanService(coreDataStack: contextManager)
        let allPlans = service.allPlans(in: contextManager.mainContext)
        guard allPlans.count > 0 else {
            viewModel = .error
            return
        }
        viewModel = .ready(allPlans, service.allPlanFeatures(in: contextManager.mainContext))
    }

    func configureAppearance() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }

    // MARK: - ImmuTablePresenter

    func present(_ controllerGenerator: @escaping ImmuTableRowControllerGenerator) -> ImmuTableAction {
        return {
            [unowned self] in
            let controller = controllerGenerator($0)
            self.present(controller, animated: true, completion: { () in
                // When the detail view is displayed as a modal on iPad, we don't receive
                // view did/will appear/disappear. Because of this, the selected row in the list
                // is never deselected. So we'll do it manually.
                if UIDevice.isPad() {
                    self.tableView.deselectSelectedRowWithAnimation(true)
                }
            })
        }
    }

    // MARK: - NoResults Handling

    private func updateNoResults() {
        noResultsViewController?.removeFromView()
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        }
    }

    private func showNoResults(_ viewModel: NoResultsViewController.Model) {

        if noResultsViewController == nil {
            noResultsViewController = NoResultsViewController.controller()
            noResultsViewController?.delegate = self
        }

        guard let noResultsViewController else {
            return
        }

        noResultsViewController.bindViewModel(viewModel)

        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        addChild(noResultsViewController)
        noResultsViewController.didMove(toParent: self)
    }

}

// MARK: - NoResultsViewControllerDelegate

extension PlanListViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}
