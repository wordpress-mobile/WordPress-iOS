import UIKit
import WordPressShared

class DomainListDomainCell: WPTableViewCell {
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var registeredMappedLabel: UILabel!
    @IBOutlet weak var primaryIndicatorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        domainLabel?.textColor = .neutral(.shade60)
        registeredMappedLabel?.textColor = .neutral(.shade40)
    }
}

struct DomainListStaticRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)
    static var customHeight: Float?

    let title: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        cell.textLabel?.text = title
    }
}

struct DomainListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(DomainListDomainCell.self)
    static var customHeight: Float? = 77

    let domain: String
    let domainType: DomainType
    let isPrimary: Bool
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? DomainListDomainCell else { return }

        cell.domainLabel?.text = domain
        cell.registeredMappedLabel?.text = domainType.description
        cell.primaryIndicatorLabel?.isHidden = !isPrimary
    }
}

class DomainsListViewController: UITableViewController, ImmuTablePresenter {
    fileprivate var viewModel: ImmuTable!

    fileprivate var fetchRequest: NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedDomain.entityName())
        request.predicate = NSPredicate(format: "%K == %@", ManagedDomain.Relationships.blog, blog)
        request.sortDescriptors = [NSSortDescriptor(key: ManagedDomain.Attributes.isPrimary, ascending: false),
                                   NSSortDescriptor(key: ManagedDomain.Attributes.domainName, ascending: true)]

        return request
    }

    @objc var blog: Blog! {
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
    @objc var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!

    @objc class func controllerWithBlog(_ blog: Blog) -> DomainsListViewController {
        let storyboard = UIStoryboard(name: "Domains", bundle: Bundle(for: self))
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

        WPStyleGuide.configureColors(view: view, tableView: tableView)

        if let dotComID = blog.dotComID?.intValue {
            service.refreshDomainsForSite(dotComID) { _ in }
        }
    }

    fileprivate func updateViewModel() {
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

        if isViewLoaded {
            tableView.reloadData()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)

        row.configureCell(cell)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = type(of: row).customHeight {
            return CGFloat(customHeight)
        }
        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }
}

extension DomainsListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateViewModel()

        tableView.reloadData()
    }
}
