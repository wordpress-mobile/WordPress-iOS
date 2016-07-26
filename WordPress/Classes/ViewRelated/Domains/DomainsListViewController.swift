import UIKit
import WordPressShared

class DomainListDomainCell: WPTableViewCell {
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var registeredMappedLabel: UILabel!
    @IBOutlet weak var primaryIndicatorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        domainLabel?.textColor = WPStyleGuide.greyDarken30()
        registeredMappedLabel?.textColor = WPStyleGuide.greyDarken10()
    }
}

struct DomainListStaticRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellDefault)
    static var customHeight: Float?

    let title: String
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        cell.textLabel?.text = title
    }
}

struct DomainListRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(DomainListDomainCell)
    static var customHeight: Float? = 77

    let domain: String
    let domainType: DomainType
    let isPrimary: Bool
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        guard let cell = cell as? DomainListDomainCell else { return }

        cell.domainLabel?.text = domain
        cell.registeredMappedLabel?.text = domainType.description
        cell.primaryIndicatorLabel?.hidden = !isPrimary
    }
}

class DomainsListViewController: UITableViewController, ImmuTablePresenter {
    private var viewModel: ImmuTable!

    private var fetchRequest: NSFetchRequest {
        let request = NSFetchRequest(entityName: ManagedDomain.entityName)
        request.predicate = NSPredicate(format: "%K == %@", ManagedDomain.Relationships.blog, blog)
        request.sortDescriptors = [NSSortDescriptor(key: ManagedDomain.Attributes.isPrimary, ascending: false),
                                   NSSortDescriptor(key: ManagedDomain.Attributes.domainName, ascending: true)]

        return request
    }

    var blog: Blog! {
        didSet {
            if let context = blog.managedObjectContext {
                fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                      managedObjectContext: context,
                                                                      sectionNameKeyPath: nil,
                                                                      cacheName: nil)
                fetchedResultsController.delegate = self
                let _ = try? fetchedResultsController.performFetch()
            }

            updateViewModel()
        }
    }
    var service: DomainsService!
    var fetchedResultsController: NSFetchedResultsController!

    class func controllerWithBlog(blog: Blog) -> DomainsListViewController {
        let storyboard = UIStoryboard(name: "Domains", bundle: NSBundle(forClass: self))
        let controller = storyboard.instantiateInitialViewController() as! DomainsListViewController

        controller.blog = blog

        if let account = blog.account {
            controller.service = DomainsService(managedObjectContext: ContextManager.sharedInstance().mainContext, account: account)
        }

        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Domains", comment: "Title for the Domains list")

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        if let dotComID = blog.dotComID {
            service.refreshDomainsForSite(Int(dotComID)) { _ in }
        }
    }

    private func updateViewModel() {
        let searchRow = DomainListStaticRow(title: "Find a new domain", action: nil)
        let connectRow = DomainListStaticRow(title: "Or connect your own domain", action: nil)

        var domainRows = [ImmuTableRow]()
        if let domains = fetchedResultsController.fetchedObjects as? [ManagedDomain] {
            domainRows = domains.map { DomainListRow(domain: $0.domainName, domainType: $0.domainType, isPrimary: $0.isPrimary, action: nil)
            }
        }

        viewModel = ImmuTable(sections: [
            ImmuTableSection(headerText: NSLocalizedString("Add A New Domain", comment: "Header title for new domain section of Domains."),
                rows: [ searchRow, connectRow ], footerText: nil),
            ImmuTableSection(headerText: NSLocalizedString("Your Domains", comment: "Header title for your domains section of Domains."),
                rows: domainRows, footerText: nil) ]
        )

        if isViewLoaded() {
            tableView.reloadData()
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(row.reusableIdentifier, forIndexPath: indexPath)

        row.configureCell(cell)

        return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = row.dynamicType.customHeight {
            return CGFloat(customHeight)
        }
        return tableView.rowHeight
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }
}

extension DomainsListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updateViewModel()

        tableView.reloadData()
    }
}
