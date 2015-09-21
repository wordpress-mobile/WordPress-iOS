import UIKit

class PeopleViewController: UITableViewController {
}

extension PeopleViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3;
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeopleCell") as! PeopleCell
        switch indexPath.row {
        case 0:
            cell.displayNameLabel.text = "Kevin Conboy"
            cell.usernameLabel.text = "@alternatekev"
            cell.roleBadge.borderColor = WPStyleGuide.People.editorColor
            cell.roleBadge.backgroundColor = WPStyleGuide.People.editorColor
            cell.roleBadge.textColor = WPStyleGuide.People.RoleBadge.textColor
            cell.roleBadge.text = "Editor"
        case 1:
            cell.displayNameLabel.text = "Mel Choyce"
            cell.usernameLabel.text = "@melchoyce"
            cell.roleBadge.borderColor = WPStyleGuide.People.authorColor
            cell.roleBadge.backgroundColor = WPStyleGuide.People.RoleBadge.textColor
            cell.roleBadge.textColor = WPStyleGuide.People.authorColor
            cell.roleBadge.text = "Author – Pending"
        case 2:
            cell.displayNameLabel.text = "Kelly Dwan"
            cell.usernameLabel.text = "@ryelle"
            cell.roleBadge.borderColor = WPStyleGuide.People.contributorColor
            cell.roleBadge.backgroundColor = WPStyleGuide.People.contributorColor
            cell.roleBadge.textColor = WPStyleGuide.People.RoleBadge.textColor
            cell.roleBadge.text = "Contributor"
        default:
            break
        }
        return cell
    }
}