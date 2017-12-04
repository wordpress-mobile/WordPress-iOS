import UIKit

class SignupDomainSuggestionViewController: UITableViewController {

    var service: DomainsService?
    fileprivate var suggestions: [String] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let moc = NSManagedObjectContext()
        let api = WordPressComRestApi(oAuthToken: "")
        let service = DomainsService(managedObjectContext: moc, remote: DomainsServiceRemote(wordPressComRestApi: api))
        service.getDomainSuggestions(base: "test suggest", success: { [weak self] (suggestions) in
            self?.suggestions = suggestions
            self?.tableView.reloadData()
        }) { (error) in
            // do nothing atm
        }
    }
}

// MARK: UITableViewDataSource

extension SignupDomainSuggestionViewController {
    fileprivate enum Sections: Int {
        case titleAndDescription = 0
        case suggestions = 1

        static var count: Int {
            return suggestions.rawValue + 1
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.titleAndDescription.rawValue:
            return 1
        case Sections.suggestions.rawValue:
            return suggestions.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case Sections.titleAndDescription.rawValue:
            cell = titleAndDescriptionCell()
        case Sections.suggestions.rawValue:
            fallthrough
        default:
            cell = buttonCell(index: indexPath.row)
        }
        return cell
    }

    private func titleAndDescriptionCell() -> UITableViewCell {
        return LoginSocialErrorCell(title: "title", description: "description")
    }

    private func buttonCell(index: Int) -> UITableViewCell {
        let cell = UITableViewCell()
        let buttonText: String
        let buttonIcon: UIImage

        let suggestion = suggestions[index]

        cell.textLabel?.text = suggestion
        cell.textLabel?.textColor = WPStyleGuide.darkGrey()
//        cell.imageView?.image = buttonIcon.imageWithTintColor(WPStyleGuide.grey())
        return cell
    }
}
