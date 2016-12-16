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

    fileprivate let noResultsView = WPNoResultsView()

    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        } else {
            hideNoResults()
        }
    }

    func showNoResults(_ viewModel: WPNoResultsView.Model) {
        noResultsView.bindViewModel(viewModel)
        if noResultsView.isDescendant(of: tableView) {
            noResultsView.centerInSuperview()
        } else {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }

    func hideNoResults() {
        noResultsView.removeFromSuperview()
    }

    static var restorationIdentifier = "PlanList"
    /// Reference to the blog object if initialized with a blog. Used for state restoration only.
    fileprivate var restorationBlogURL: URL? = nil

    convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let service = PlanService(blog: blog, store: StoreKitStore()) else {
            return nil
        }

        self.init(siteID: Int(blog.dotComID!), service: service)
        restorationBlogURL = blog.objectID.uriRepresentation()
    }

    let siteID: Int
    let service: PlanService<StoreKitStore>
    init(siteID: Int, service: PlanService<StoreKitStore>) {
        self.siteID = siteID
        self.service = service
        super.init(style: .grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
        PlanListViewController.restorationIdentifier = PlanListViewController.restorationIdentifier
        restorationClass = PlanListViewController.self
        noResultsView.delegate = self
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
            self.present(controller, animated: true, completion: { _ in
                // When the detail view is displayed as a modal on iPad, we don't receive
                // view did/will appear/disappear. Because of this, the selected row in the list
                // is never deselected. So we'll do it manually.
                if UIDevice.isPad() {
                    self.tableView.deselectSelectedRowWithAnimation(true)
                }
            })
        }
    }
}

// MARK: - WPNoResultsViewDelegate

extension PlanListViewController: WPNoResultsViewDelegate {
    func didTap(_ noResultsView: WPNoResultsView!) {
        SupportViewController.showFromTabBar()
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
        guard let objectID = context?.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: blogURL),
            let object = try? context?.existingObject(with: objectID),
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
