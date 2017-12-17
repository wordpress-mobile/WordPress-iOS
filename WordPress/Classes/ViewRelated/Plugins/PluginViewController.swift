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
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows(PluginViewModel.immutableRows, tableView: tableView)
        viewModelReceipt = viewModel.onChange { [weak self] in
            self?.bindViewModel()
        }
        bindViewModel()
    }

    func bindViewModel() {
        handler.viewModel = viewModel.tableViewModel
        title = viewModel.title
    }
}
