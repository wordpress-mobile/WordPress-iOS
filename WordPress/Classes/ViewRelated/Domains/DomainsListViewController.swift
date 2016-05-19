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
        let request = NSFetchRequest(entityName: Domain.entityName)
        request.predicate = NSPredicate(format: "%K == %@", "blog", blog)
        request.sortDescriptors = [NSSortDescriptor(key: "isPrimary", ascending: false), NSSortDescriptor(key: "domain", ascending: true)]

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
        controller.service = DomainsService(blog: blog)

        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Domains", comment: "Title for the Domains list")

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        service.refreshBlogDomains { success in

        }
    }

    private func updateViewModel() {
        let searchRow = DomainListStaticRow(title: "Find a new domain", action: nil)
        let connectRow = DomainListStaticRow(title: "Or connect your own domain", action: nil)

        var domainRows = [ImmuTableRow]()
        if let domains = fetchedResultsController.fetchedObjects as? [ManagedDomain] {
            domainRows = domains.map { DomainListRow(domain: $0.domain, domainType: $0.domainType, isPrimary: $0.isPrimary, action: nil)
            }
        }

        viewModel = ImmuTable(sections: [
            ImmuTableSection(headerText: "Add A New Domain", rows: [ searchRow, connectRow ], footerText: nil),
            ImmuTableSection(headerText: "Your Domains", rows: domainRows, footerText: nil) ]
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

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = self.tableView(tableView, titleForHeaderInSection: section) where !title.isEmpty {
            let header = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
            header.title = title
            return header
        } else {
            return nil
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let headerView = self.tableView(tableView, viewForHeaderInSection: section) as? WPTableViewSectionHeaderFooterView {
            return WPTableViewSectionHeaderFooterView.heightForHeader(headerView.title, width: CGRectGetWidth(view.bounds))
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }
}

extension DomainsListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updateViewModel()

        tableView.reloadData()
    }
}
