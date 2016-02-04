import UIKit
import WordPressShared

class PlanListViewController: UITableViewController {
    let cellIdentifier = "PlanListItem"
    let availablePlans = [
        Plan.Free,
        Plan.Premium,
        Plan.Business
    ]
    let activePlan = Plan.Free

    init() {
        super.init(style: .Grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(WPTableViewCellSubtitle.self, forCellReuseIdentifier: cellIdentifier)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availablePlans.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        let plan = availablePlans[indexPath.row]

        if plan == activePlan {
            cell.imageView?.image = plan.activeImage
        } else {
            cell.imageView?.image = plan.image
        }
        cell.textLabel?.text = plan.title
        cell.detailTextLabel?.text = plan.description

        cell.selectionStyle = .None

        return cell
    }
}
