import Foundation
import WordPressFlux

class PluginViewController: UITableViewController {

    fileprivate lazy var handler: ImmuTableViewHandler = {
        let handler = ImmuTableViewHandler(takeOver: self)
        handler.automaticallyDeselectCells = true
        return handler
    }()

    fileprivate let viewModel: PluginViewModel
    private var noResultsViewController: NoResultsViewController?

    var viewModelReceipt: Receipt?

    init(plugin: Plugin, capabilities: SitePluginCapabilities, site: JetpackSiteRef) {
        viewModel = PluginViewModel(plugin: plugin, capabilities: capabilities, site: site)
        super.init(style: .grouped)
        commonInit()
    }

    init(directoryEntry: PluginDirectoryEntry, site: JetpackSiteRef) {
        viewModel = PluginViewModel(directoryEntry: directoryEntry, site: site)
        super.init(style: .grouped)
        commonInit()
    }

    init(slug: String, site: JetpackSiteRef) {
        viewModel = PluginViewModel(slug: slug, site: site)
        super.init(style: .grouped)
        commonInit()
    }

    private func commonInit() {
        viewModel.present = { [weak self] viewController in
            self?.present(viewController, animated: true)
        }
        viewModel.dismiss = { [weak self] in
            guard let navigationController = self?.navigationController,
                navigationController.topViewController == self else {
                    return
            }
            navigationController.popViewController(animated: true)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeDynamicType),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didChangeDynamicType() {
        // (non-trivial) NSAttributedStrings and Dynamic Type don't work super well with each other.
        // We use fairly complex NSAttributedStrings in this view — so we subscribe to the notification
        // from the system, in order to correctly redraw the screen.
        bindViewModel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        ImmuTable.registerRows(PluginViewModel.immutableRows, tableView: tableView)
        viewModelReceipt = viewModel.onChange { [weak self] in
            self?.bindViewModel()
        }

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        bindViewModel()
        observeNetworkStatus()
    }

    private func setupViews() {
        tableView.separatorInset = UIEdgeInsets()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }

    private func bindViewModel() {
        handler.viewModel = viewModel.tableViewModel
        title = viewModel.title
        updateNoResults()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = handler.viewModel.rowAtIndexPath(indexPath)
        row.action?(row)

        guard let collapsibleCell = tableView.cellForRow(at: indexPath) as? ExpandableCell else { return }

        collapsibleCell.toggle()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // This is a hack/work-around to remove the gap from the top of the tableView — the system leaves
        // a gap with a `grouped` style by default — we want the banner up top, without any gaps.
        guard section != 0 else {
            return CGFloat.leastNonzeroMagnitude
        }

        return Constants.tableViewHeaderHeight
    }

    private enum Constants {
        static var tableViewHeaderHeight: CGFloat = 17.5
    }
}

// MARK: - NoResultsViewControllerDelegate

extension PluginViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}

// MARK: - NoResults Handling

private extension PluginViewController {
    func updateNoResults() {
        noResultsViewController?.removeFromView()
        if let noResultsViewModel = viewModel.noResultsViewModel() {
            showNoResults(noResultsViewModel)
        }
    }

    func showNoResults(_ viewModel: NoResultsViewController.Model) {
        let noResultsViewController = getNoResultsViewController()

        noResultsViewController.bindViewModel(viewModel)

        addAsSubviewIfNeeded(noResultsViewController)
    }

    private func addAsSubviewIfNeeded(_ noResultsViewController: NoResultsViewController) {
        if noResultsViewController.view.superview != tableView {
            tableView.addSubview(withFadeAnimation: noResultsViewController.view)
            addChild(noResultsViewController)
            noResultsViewController.didMove(toParent: self)
            noResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
            tableView.pinSubviewToSafeArea(noResultsViewController.view)
        }
    }

    private func addChildController(_ controller: UIViewController) {

    }

    private func getNoResultsViewController() -> NoResultsViewController {
        if let noResultsViewController = self.noResultsViewController {
            return noResultsViewController
        }

        let noResultsViewController = NoResultsViewController.controller()
        noResultsViewController.delegate = self
        self.noResultsViewController = noResultsViewController

        return noResultsViewController
    }
}

extension PluginViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        if active {
            viewModel.networkStatusDidChange(active: active)
        }
    }
}
