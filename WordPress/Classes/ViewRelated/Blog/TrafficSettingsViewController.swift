import Foundation

class TrafficSettingsViewController: UITableViewController, ImmuTablePresenter {

    /// Designated Initializer
    ///
    /// - Parameter
    /// - Blog: The blog for which we want to display the traffic settings
    /// - OnChange: The closure to be executed when the switch is toggled
    ///
    @objc public convenience init(blog: Blog, onChange: @escaping ((Bool) -> Void)) {
        self.init(style: .grouped)
        self.blog = blog
        self.onChange = onChange
    }

    // MARK: - Private Properties

    /// Blog for which to show the Traffic settings
    ///
    private var blog: Blog!

    /// Callback to be executed whenever the Blog's amp enabled setting changes.
    ///
    private var onChange: ((Bool) -> Void)!

    /// ImmuTableViewHandler, takes over the datasource, delegate from this VC
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    override func viewDidLoad() {
        title = NSLocalizedString("Traffic", comment: "Title for Traffic settings")
        ImmuTable.registerRows([SwitchRow.self], tableView: tableView)

        // setup the viewModel
        let isAMPEnabled = self.blog.settings?.ampEnabled ?? false
        handler.viewModel = TrafficSettingsViewModel.ready(isAMPEnabled, self.onChange).tableViewModel()
    }
}

enum TrafficSettingsViewModel {
    /**
     - Parameters
     - First param: - Indicates if AMP is enabled for the site
     - Second param: - Action block to be executed when user toggles the Switch.
     */
    case ready(Bool, ((Bool) -> Void))

    func tableViewModel() -> ImmuTable {
        switch self {
        case .ready(let isAMPEnabled, let action):
            let switchTitle: String = NSLocalizedString("Accelerated Mobile Pages (AMP)", comment: "Label for AMP toggle")
            let row = SwitchRow(title: switchTitle, value: isAMPEnabled, onChange: action)
            let section = ImmuTableSection(rows: [row])
            return ImmuTable(sections: [section])
        }
    }
}
