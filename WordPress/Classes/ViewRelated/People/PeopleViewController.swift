import UIKit

class PeopleViewController: UITableViewController {
    let models: People = {
        let person1 = Person(
            ID: 0,
            username: "alternatekev",
            firstName: "Kevin",
            lastName: "Conboy",
            displayName: "Kevin Conboy",
            role: .Editor,
            pending: false,
            siteID: 0,
            avatarURL: nil
        )
        let person2 = Person(
            ID: 0,
            username: "melchoyce",
            firstName: "Mel",
            lastName: "Choyce",
            displayName: "Mel Choyce",
            role: .Author,
            pending: true,
            siteID: 0,
            avatarURL: nil
        )
        let person3 = Person(
            ID: 0,
            username: "ryelle",
            firstName: "Kelly",
            lastName: "Dwan",
            displayName: "Kelly Dwan",
            role: .Contributor,
            pending: false,
            siteID: 0,
            avatarURL: nil
        )
        return [person1, person2, person3]
    }()
}

extension PeopleViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count;
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeopleCell") as! PeopleCell
        let person = models[indexPath.row]
        let viewModel = PeopleCellViewModel(person: person)

        cell.bindViewModel(viewModel)
        
        return cell
    }
}