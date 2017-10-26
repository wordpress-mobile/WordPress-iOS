import Foundation

class PluginViewModel {
    var plugin: PluginState {
        didSet {
            onModelChange?()
        }
    }
    let service: PluginServiceRemote

    init(plugin: PluginState, service: PluginServiceRemote) {
        self.plugin = plugin
        self.service = service
    }

    var onModelChange: (() -> Void)?
    var present: ((UIViewController) -> Void)?

    var tableViewModel: ImmuTable {
        let activeRow = SwitchRow(
            title: NSLocalizedString("Active", comment: "Whether a plugin is active on a site"),
            value: plugin.active,
            onChange: { (active) in
        })
        let autoupdatesRow = SwitchRow(
            title: NSLocalizedString("Autoupdates", comment: "Whether a plugin has enabled automatic updates"),
            value: plugin.autoupdate,
            onChange: { (autoupdate) in
        })
        let removeRow = DestructiveButtonRow(
            title: NSLocalizedString("Remove Plugin", comment: "Button to remove a plugin from a site"),
            action: { [unowned self] _ in
                let alert = self.confirmRemovalAlert(plugin: self.plugin)
                self.present?(alert)
            },
            accessibilityIdentifier: "remove-plugin")

        let directoryLink = NavigationItemRow(
            title: NSLocalizedString("WordPress.org Plugin page", comment: "Link to a plugin's page in the plugin directory"),
            action: { [unowned self] _ in
                let controller = WebViewControllerFactory.controller(url: self.plugin.directoryURL)
                let navigationController = UINavigationController(rootViewController: controller)
                self.present?(navigationController)
        })

        var homeLink: ImmuTableRow?
        if let homeURL = plugin.homeURL {
            homeLink = NavigationItemRow(
                title: NSLocalizedString("Plugin homepage", comment: "Link to a plugin's home page"),
                action: { [unowned self] _ in
                    let controller = WebViewControllerFactory.controller(url: homeURL)
                    let navigationController = UINavigationController(rootViewController: controller)
                    self.present?(navigationController)
            })
        }

        return ImmuTable(optionalSections: [
            ImmuTableSection(optionalRows: [
                activeRow,
                autoupdatesRow
                ]),
            ImmuTableSection(optionalRows: [
                homeLink
                ]),
            ImmuTableSection(optionalRows: [
                removeRow
                ])
            ])
    }

    private func confirmRemovalAlert(plugin: PluginState) -> UIAlertController {
        let message = NSLocalizedString("Are you sure you want to remove \(plugin.name)?", comment: "Text for the alert to confirm a plugin removal")
        let alert = UIAlertController(
            title: NSLocalizedString("Remove Plugin?", comment: "Title for the alert to confirm a plugin removal"),
            message: message, preferredStyle: .alert)
        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel removing a plugin"))
        alert.addDestructiveActionWithTitle(NSLocalizedString("Remove", comment: "Alert button to confirm a plugin to be removed"), handler: { _ in
            // TODO: Remove plugin
        })
        return alert
    }

    var title: String {
        return plugin.name
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [SwitchRow.self, DestructiveButtonRow.self, NavigationItemRow.self]
    }
}

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

    init(plugin: PluginState, siteID: Int, service: PluginServiceRemote) {
        self.siteID = siteID
        self.plugin = plugin
        viewModel = PluginViewModel(plugin: plugin, service: service)
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
