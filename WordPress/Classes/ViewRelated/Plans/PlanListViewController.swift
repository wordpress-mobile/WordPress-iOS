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

    @objc static let restorationIdentifier = "PlanList"

    override init(style: UITableView.Style) {
        super.init(style: .grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
        // Need to use `super` to work around a Swift compiler bug
        // https://bugs.swift.org/browse/SR-3465
        super.restorationIdentifier = PlanListViewController.restorationIdentifier
        restorationClass = PlanListViewController.self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        ImmuTable.registerRows([PlanListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModelWithPresenter(self)
        updateNoResults()
        updateViewModel()
        syncPlans()
    }

    func syncPlans() {
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.defaultWordPressComAccount() else {
            return
        }

        let plansService = PlanService.init(managedObjectContext: ContextManager.sharedInstance().mainContext)
        plansService.getWpcomPlans(account,
                                   success: { [weak self] in
            self?.updateViewModel()

        }, failure: { error in
            DDLogInfo(error.debugDescription)
        })
    }

    func updateViewModel() {
        let service = PlanService.init(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let allPlans = service.allPlans()
        guard allPlans.count > 0 else {
            viewModel = .error
            return
        }
        viewModel = .ready(allPlans, service.allPlanFeatures())
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

        guard let noResultsViewController = noResultsViewController else {
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

// MARK: - UIViewControllerRestoration

extension PlanListViewController: UIViewControllerRestoration {

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last,
            identifier == PlanListViewController.restorationIdentifier else {
            return nil
        }

        return PlanListViewController(style: .grouped)
    }

}
