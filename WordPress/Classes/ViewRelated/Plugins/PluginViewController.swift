import Foundation

class PluginViewController: UITableViewController {
    let siteID: Int
    var plugin: PluginState {
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

    init(plugin: PluginState, capabilities: SitePluginCapabilities, siteID: Int, service: PluginServiceRemote) {
        self.siteID = siteID
        self.plugin = plugin
        viewModel = PluginViewModel(plugin: plugin, capabilities: capabilities, service: service)
        super.init(style: .grouped)
        viewModel.onModelChange = bindViewModel
        viewModel.present = { [weak self] viewController in
            self?.present(viewController, animated: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ImmuTable.registerRows(PluginViewModel.immutableRows, tableView: tableView)
        bindViewModel()
    }

    func bindViewModel() {
        handler.viewModel = viewModel.tableViewModel
        title = viewModel.title
    }
}
