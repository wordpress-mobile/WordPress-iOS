import UIKit
import WordPressShared

final class PlanListViewController: UITableViewController, ImmuTablePresenter {
    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()
    fileprivate var viewModel: PlanListViewModel = .loading {
        didSet {
            handler.viewModel = viewModel.tableViewModelWithPresenter(self, planService: service)
            updateNoResults()
        }
    }

    fileprivate var noResultsViewController: NoResultsViewController?

    @objc static let restorationIdentifier = "PlanList"
    /// Reference to the blog object if initialized with a blog. Used for state restoration only.
    fileprivate var restorationBlogURL: URL? = nil

    @objc convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let service = PlanService(blog: blog, store: StoreKitStore()),
            let siteID = blog.dotComID?.intValue
        else {
            return nil
        }

        self.init(siteID: siteID, service: service)
        restorationBlogURL = blog.objectID.uriRepresentation()
    }

    @objc let siteID: Int
    let service: PlanService<StoreKitStore>
    init(siteID: Int, service: PlanService<StoreKitStore>) {
        self.siteID = siteID
        self.service = service
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
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([PlanListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModelWithPresenter(self, planService: service)
        updateNoResults()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        service.plansWithPricesForBlog(siteID,
            success: { result in
                self.viewModel = .ready(result)
            },
            failure: { error in
                self.viewModel = .error(String(describing: error))
            }
        )
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
        addChildViewController(noResultsViewController)
        noResultsViewController.didMove(toParentViewController: self)
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
    enum EncodingKey {
        static let blogURL = "blogURL"
    }

    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String, identifier == PlanListViewController.restorationIdentifier else {
            return nil
        }

        guard let blogURL = coder.decodeObject(forKey: EncodingKey.blogURL) as? URL else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        guard let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: blogURL),
            let object = try? context.existingObject(with: objectID),
            let blog = object as? Blog else {
                return nil
        }
        return PlanListViewController(blog: blog)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        if let blogURL = restorationBlogURL {
            coder.encode(blogURL, forKey: EncodingKey.blogURL)
        }
    }
}
