import UIKit

class SignupDomainSuggestionViewController: UITableViewController {

    var service: DomainsService?
    private var siteTitleSuggestions: [String] = []
    private var searchSuggestions: [String] = []
    private var isSearching: Bool = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.register(UINib(nibName: "SiteCreationDomainSearchTableViewCell", bundle: nil), forCellReuseIdentifier: SiteCreationDomainSearchTableViewCell.cellIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)



        isSearching = true
        let moc = NSManagedObjectContext()
        let api = WordPressComRestApi(oAuthToken: "")
        let service = DomainsService(managedObjectContext: moc, remote: DomainsServiceRemote(wordPressComRestApi: api))
        service.getDomainSuggestions(base: "test suggest", success: { [weak self] (suggestions) in
            self?.siteTitleSuggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integer: Sections.siteTitleSuggestions.rawValue), with: .top)
            self?.isSearching = false
        }) { [weak self] (error) in
            self?.isSearching = false
            // do nothing atm
        }
    }
}

// MARK: UITableViewDataSource

extension SignupDomainSuggestionViewController {
    fileprivate enum Sections: Int {
        case titleAndDescription = 0
        case searchField = 1
        case searchSuggestions = 2
        case siteTitleSuggestions = 3

        static var count: Int {
            return siteTitleSuggestions.rawValue + 1
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.titleAndDescription.rawValue:
            return 1
        case Sections.searchField.rawValue:
            return 1
        case Sections.searchSuggestions.rawValue:
            return searchSuggestions.count
        case Sections.siteTitleSuggestions.rawValue:
            return siteTitleSuggestions.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case Sections.titleAndDescription.rawValue:
            cell = titleAndDescriptionCell()
        case Sections.searchField.rawValue:
            cell = searchFieldCell()
        case Sections.searchSuggestions.rawValue:
            cell = searchButtonCell(index: indexPath.row)
        case Sections.siteTitleSuggestions.rawValue:
            fallthrough
        default:
            cell = buttonCell(index: indexPath.row)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = WPStyleGuide.greyLighten20()
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }

    private func titleAndDescriptionCell() -> UITableViewCell {
        return LoginSocialErrorCell(title: "title", description: "description")
    }

    private func searchFieldCell() -> SiteCreationDomainSearchTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SiteCreationDomainSearchTableViewCell.cellIdentifier) as? SiteCreationDomainSearchTableViewCell else {
            return SiteCreationDomainSearchTableViewCell(placeholder: "")
        }
        cell.delegate = self
        return cell
    }

    private func buttonCell(index: Int) -> UITableViewCell {
        let cell = UITableViewCell()

        let suggestion = siteTitleSuggestions[index]

        cell.textLabel?.text = suggestion
        cell.textLabel?.textColor = WPStyleGuide.darkGrey()
        return cell
    }

    private func searchButtonCell(index: Int) -> UITableViewCell {
        let cell = UITableViewCell()

        let suggestion = searchSuggestions[index]

        cell.textLabel?.text = suggestion
        cell.textLabel?.textColor = WPStyleGuide.darkGrey()
        return cell
    }
}

// MARK: SiteCreationDomainSearchTableViewCellDelegate

extension SignupDomainSuggestionViewController: SiteCreationDomainSearchTableViewCellDelegate {
    func startSearch(for searchTerm: String) {
        guard !isSearching else {
            return
        }

        isSearching = true

        let moc = NSManagedObjectContext()
        let api = WordPressComRestApi(oAuthToken: "")
        let service = DomainsService(managedObjectContext: moc, remote: DomainsServiceRemote(wordPressComRestApi: api))
        service.getDomainSuggestions(base: searchTerm, success: { [weak self] (suggestions) in
            self?.isSearching = false
            self?.searchSuggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integer: Sections.searchSuggestions.rawValue), with: .top)
        }) { [weak self] (error) in
            self?.isSearching = false
        }
    }
}
