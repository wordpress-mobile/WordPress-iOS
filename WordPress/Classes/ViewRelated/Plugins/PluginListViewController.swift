import UIKit
import WordPressKit

struct PluginListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    let name: String
    let version: String?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = version
        cell.selectionStyle = .none
    }
}

enum PluginListViewModel {
    case loading
    case ready([PluginState])
    case error(String)

    var noResultsViewModel: WPNoResultsView.Model? {
        switch self {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plugins...", comment: "Text displayed while loading plugins for a site")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading plugins", comment: ""),
                    buttonTitle: NSLocalizedString("Contact support", comment: "")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: ""),
                    message: NSLocalizedString("An active internet connection is required to view plugins", comment: "")
                )
            }
        }
    }

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter?) -> ImmuTable {
        switch self {
        case .loading, .error:
            return .Empty
        case .ready(let pluginStates):
            let rows = pluginStates.map({ pluginState in
                return PluginListRow(name: pluginState.name, version: pluginState.version)
            })
            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
                ])
        }
    }
}

class PluginListViewController: UITableViewController, ImmuTablePresenter {
    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()
    fileprivate var viewModel: PluginListViewModel = .loading {
        didSet {
            handler.viewModel = viewModel.tableViewModelWithPresenter(self)
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

    convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let api = blog.wordPressComRestApi(),
            let service = PluginServiceRemote(wordPressComRestApi: api) else {
            return nil
        }

        self.init(siteID: Int(blog.dotComID!), service: service)
    }

    let siteID: Int
    let service: PluginServiceRemote
    init(siteID: Int, service: PluginServiceRemote) {
        self.siteID = siteID
        self.service = service
        super.init(style: .grouped)
        title = NSLocalizedString("Plugins", comment: "Title for the plugin manager")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([PluginListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModelWithPresenter(self)
        updateNoResults()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        service.getPlugins(siteID: siteID, success: { result in
            self.viewModel = .ready(result)
        }, failure: { error in
            self.viewModel = .error(String(describing: error))
        })
    }

}
