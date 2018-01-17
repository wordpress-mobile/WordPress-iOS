import Foundation
import WordPressFlux

class PluginViewController: UITableViewController {
    var plugin: Plugin {
        didSet {
            viewModel.plugin = plugin
        }
    }

    fileprivate lazy var handler: ImmuTableViewHandler = {
        let handler = ImmuTableViewHandler(takeOver: self)
        handler.automaticallyDeselectCells = true
        return handler
    }()

    fileprivate let viewModel: PluginViewModel
    var viewModelReceipt: Receipt?

    init(plugin: Plugin, capabilities: SitePluginCapabilities, site: JetpackSiteRef) {
        self.plugin = plugin
        viewModel = PluginViewModel(plugin: plugin, capabilities: capabilities, site: site)
        super.init(style: .grouped)
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        ImmuTable.registerRows(PluginViewModel.immutableRows, tableView: tableView)
        viewModelReceipt = viewModel.onChange { [weak self] in
            self?.bindViewModel()
        }
        bindViewModel()
    }

    private func setupViews() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.01))
        // This is a hack/work-around to remove the gap from the top of the tableView — the system leaves
        // a gap with a `grouped` style by default — we want the banner up top, without any gaps.
        tableView.separatorInset = UIEdgeInsets()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    private func bindViewModel() {
        handler.viewModel = viewModel.tableViewModel
        title = viewModel.title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = handler.viewModel.rowAtIndexPath(indexPath)
        row.action?(row)

        guard let collapsibleCell = tableView.cellForRow(at: indexPath) as? ExpandableCell else { return }

        collapsibleCell.toggle()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

}
