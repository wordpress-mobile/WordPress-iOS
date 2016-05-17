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
    private var viewModel: ImmuTable!

    private var fetchRequest: NSFetchRequest {
        let request = NSFetchRequest(entityName: Domain.entityName)
        request.predicate = NSPredicate(format: "%K == %@", "blog", blog)
        request.sortDescriptors = [NSSortDescriptor(key: "domain", ascending: true)]

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
        ImmuTable.registerRows([DomainListRow.self], tableView: tableView)

        service.refreshBlogDomains { success in

        }
    }

    private func updateViewModel() {
        let searchRow = DomainListRow(title: "Find a new domain", action: nil)
        let connectRow = DomainListRow(title: "Or connect your own domain", action: nil)

        var domainRows = [ImmuTableRow]()
        if let domains = fetchedResultsController.fetchedObjects as? [ManagedDomain] {
            domainRows = domains.map { DomainListRow(title: $0.domain, action: nil) }
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

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }

    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footerText
    }
}

extension DomainsListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updateViewModel()

        tableView.reloadData()
    }
}
