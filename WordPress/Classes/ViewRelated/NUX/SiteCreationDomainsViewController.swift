import UIKit

class SiteCreationDomainsViewController: UITableViewController {
    var helpBadge: WPNUXHelpBadgeLabel!
    var helpButton: UIButton!

    open var siteName: String?

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
        tableView.register(UINib(nibName: "SiteCreationDomainsActivityTableViewCell", bundle: nil), forCellReuseIdentifier: SiteCreationDomainsActivityTableViewCell.cellIdentifier)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = WPStyleGuide.greyLighten30()

        let (helpButtonResult, helpBadgeResult) = addHelpButtonToNavController()
        helpButton = helpButtonResult
        helpBadge = helpBadgeResult
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // only procede with initial search if we don't have site title suggestions yet (hopefully only the first time)
        guard siteTitleSuggestions.count < 1,
            let nameToSearch = siteName else {
            return
        }

        suggestDomains(for: nameToSearch) { [weak self] (suggestions) in
            self?.siteTitleSuggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integersIn: Sections.searchField.rawValue...Sections.siteTitleSuggestions.rawValue), with: .automatic)
        }
    }

    private func suggestDomains(for searchTerm: String, addSuggestions: @escaping (_: [String]) ->()) {
        guard !isSearching else {
            return
        }

        isSearching = true

        let api = WordPressComRestApi(oAuthToken: "")
        let service = DomainsService(managedObjectContext: ContextManager.sharedInstance().mainContext, remote: DomainsServiceRemote(wordPressComRestApi: api))
        tableView.reloadSections(IndexSet(integer: Sections.searchSuggestions.rawValue), with: .top)
        service.getDomainSuggestions(base: searchTerm, success: { [weak self] (suggestions) in
            self?.isSearching = false
            addSuggestions(suggestions)
            self?.tableView.reloadSections(IndexSet(integer: Sections.searchSuggestions.rawValue), with: .automatic)
        }) { [weak self] (error) in
            self?.isSearching = false
        }
    }
}

// MARK: - LoginWithLogoAndHelpViewController methods

extension SiteCreationDomainsViewController: LoginWithLogoAndHelpViewController {
    func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(sourceTag: .wpComLogin)
    }

    func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification) {
        let count = HelpshiftUtils.unreadNotificationCount()
        helpBadge.text = "\(count)"
        helpBadge.isHidden = (count == 0)
    }
}

// MARK: UITableViewDataSource

extension SiteCreationDomainsViewController {
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
            if siteTitleSuggestions.count == 0 && searchSuggestions.count == 0 {
                return 0
            } else {
                return 1
            }
        case Sections.searchSuggestions.rawValue:
            if isSearching {
                return 1
            } else {
                return searchSuggestions.count
            }
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
            if isSearching {
                cell = activityCell()
            } else {
                cell = searchButtonCell(index: indexPath.row)
            }
        case Sections.siteTitleSuggestions.rawValue:
            fallthrough
        default:
            cell = buttonCell(index: indexPath.row)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == Sections.siteTitleSuggestions.rawValue || section == Sections.searchField.rawValue else {
            return nil
        }
        let footer = UIView()
        footer.backgroundColor = WPStyleGuide.greyLighten20()
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == Sections.siteTitleSuggestions.rawValue || section == Sections.searchField.rawValue else {
            return 0.0
        }
        return 0.5
    }

    // MARK: table view cells

    private func activityCell() -> SiteCreationDomainsActivityTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SiteCreationDomainsActivityTableViewCell.cellIdentifier) as? SiteCreationDomainsActivityTableViewCell else {
            let newCell = SiteCreationDomainsActivityTableViewCell(style: .default, reuseIdentifier: SiteCreationDomainsActivityTableViewCell.cellIdentifier)
            newCell.activitySpinner?.startAnimating()
            return newCell
        }
        cell.activitySpinner?.startAnimating()
        return cell
    }

    private func titleAndDescriptionCell() -> UITableViewCell {
        let title = NSLocalizedString("Step 4 of 4", comment: "Title for last step in the site creation process.").localizedUppercase
        let description = NSLocalizedString("Pick an available \"yourname.wordpress.com\" address to let people find you on the web.", comment: "Description of how to pick a domain name during the site creation process")
        let cell = LoginSocialErrorCell(title: title, description: description)
        cell.selectionStyle = .none
        return cell
    }

    private func searchFieldCell() -> SiteCreationDomainSearchTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SiteCreationDomainSearchTableViewCell.cellIdentifier) as? SiteCreationDomainSearchTableViewCell else {
            return SiteCreationDomainSearchTableViewCell(placeholder: "")
        }
        cell.delegate = self
        cell.selectionStyle = .none
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

// MARK: UITableViewDelegate

extension SiteCreationDomainsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDomain: String
        switch indexPath.section {
        case Sections.searchSuggestions.rawValue:
            selectedDomain = searchSuggestions[indexPath.row]
        case Sections.siteTitleSuggestions.rawValue:
            selectedDomain = siteTitleSuggestions[indexPath.row]
        default:
            return
        }

        tableView.deselectSelectedRowWithAnimation(true)
        let message = "'\(selectedDomain)' selected.\nThis is a work in progress. If you need to create a site, disable the siteCreation feature flag."
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addDefaultActionWithTitle("OK")
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: SiteCreationDomainSearchTableViewCellDelegate

extension SiteCreationDomainsViewController: SiteCreationDomainSearchTableViewCellDelegate {
    func startSearch(for searchTerm: String) {
        suggestDomains(for: searchTerm) { [weak self] (suggestions) in
            self?.searchSuggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integer: Sections.searchSuggestions.rawValue), with: .automatic)
        }
    }
}
