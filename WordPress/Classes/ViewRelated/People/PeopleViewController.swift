import UIKit

public class PeopleViewController: UITableViewController {
    var models = [Person]()
    public var blog: Blog?

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count;
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeopleCell") as! PeopleCell
        let person = models[indexPath.row]
        let viewModel = PeopleCellViewModel(person: person)

        cell.bindViewModel(viewModel)
        
        return cell
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if models.count == 0 {
            refreshControl?.beginRefreshing()
            refresh()
        }
    }

    @IBAction func refresh() {
        let remote = PeopleRemote(api: blog!.account.restApi)
        remote.getTeamFor(blog!.dotComID().integerValue,
            success: {
                (people) -> () in

                self.models = people
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            },
            failure: {
                (error) -> () in

                // TODO: handle failure
                DDLogSwift.logError(String(error))
                self.refreshControl?.endRefreshing()
        })
    }
}