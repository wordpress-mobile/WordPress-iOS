import UIKit
import WordPressShared

public class PeopleViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    public var blog: Blog?
    private lazy var resultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@", self.blog!.dotComID)
        // FIXME(@koke, 2015-11-02): my user should be first
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        let context = ContextManager.sharedInstance().mainContext
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    
    // MARK: - UITableView Methods
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeopleCell") as! PeopleCell
        let person = personAtIndexPath(indexPath)
        let viewModel = PeopleCellViewModel(person: person)

        cell.bindViewModel(viewModel)

        return cell
    }

    
    // MARK: - NSFetchedResultsController Methods
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }

    
    // MARK: - View Lifecycle Methods
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try resultsController.performFetch()
        } catch {
            DDLogSwift.logError("Error fetching People: \(error)")
        }
        
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
// TODO: JLP May.3.2016. Spinner??
        if resultsController.fetchedObjects?.count == 0 {
            refreshControl?.beginRefreshing()
            refresh()
        }
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let personViewController = segue.destinationViewController as? PersonViewController,
            let selectedIndexPath = tableView.indexPathForSelectedRow
        {
            personViewController.person = personAtIndexPath(selectedIndexPath)
            personViewController.blog = blog
        }
    }

    
    // MARK: - Helpers
    
    @IBAction func refresh() {
        let service = PeopleService(blog: blog!)
        service.refreshTeam { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }

    private func personAtIndexPath(indexPath: NSIndexPath) -> Person {
        let managedPerson = resultsController.objectAtIndexPath(indexPath) as! ManagedPerson
        let person = Person(managedPerson: managedPerson)
        return person
    }
}
