import UIKit
import WordPressShared

struct DomainListRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellDefault)
    static var customHeight: Float?

    let title: String
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        cell.textLabel?.text = title
    }
}

class DomainsListViewController: UITableViewController, ImmuTablePresenter {
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private var viewModel: ImmuTable = {
        let searchRow = DomainListRow(title: "Find a new domain", action: nil)
        let connectRow = DomainListRow(title: "Or connect your own domain", action: nil)
        let domainRow = DomainListRow(title: "hawthornecoffeeco.com", action: nil)

        return ImmuTable(sections: [
            ImmuTableSection(headerText: "Add A New Domain",
                rows: [ searchRow, connectRow ], footerText: nil),
            ImmuTableSection(headerText: "Your Domains",
                rows: [ domainRow ], footerText: nil) ])
    }()

    var blog: Blog!

    class func controllerWithBlog(blog: Blog) -> DomainsListViewController {
        let storyboard = UIStoryboard(name: "Domains", bundle: NSBundle(forClass: self))
        let controller = storyboard.instantiateInitialViewController() as! DomainsListViewController

        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Domains", comment: "Title for the Domains list")

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        ImmuTable.registerRows([DomainListRow.self], tableView: tableView)
        handler.viewModel = viewModel
    }
}
