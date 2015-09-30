import UIKit

public class PeopleViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    public var blog: Blog?
    private lazy var resultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@", self.blog!.dotComID())
        // FIXME: my user should be first
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true, selector: "localizedCaseInsensitiveCompare:")]
        let context = ContextManager.sharedInstance().mainContext
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0;
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

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try resultsController.performFetch()
        } catch {
            DDLogSwift.logError("Error fetching People: \(error)")
        }
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if resultsController.fetchedObjects?.count == 0 {
            refreshControl?.beginRefreshing()
            refresh()
        }
    }

    @IBAction func refresh() {
        let service = PeopleService(blog: blog!)
        service.refreshTeam { _ in
            self.refreshControl?.endRefreshing()
        }
    }

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowPerson" {
            let indexPath = tableView.indexPathForSelectedRow!
            let person = personAtIndexPath(indexPath)
            let controller = segue.destinationViewController as! PersonViewController
            controller.blog = blog
            controller.personID = person.ID
        }
    }

    private func personAtIndexPath(indexPath: NSIndexPath) -> Person {
        let managedPerson = resultsController.objectAtIndexPath(indexPath) as! ManagedPerson
        let person = Person(managedPerson: managedPerson)
        return person
    }
}