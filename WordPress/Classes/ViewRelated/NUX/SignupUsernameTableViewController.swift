import SVProgressHUD

protocol SignupUsernameTableViewControllerDelegate {
    func usernameSelected(_ username: String)
    func newSearchStarted()
}

class SignupUsernameTableViewController: NUXTableViewController {
    open var currentUsername: String?
    open var displayName: String?
    open var delegate: SignupUsernameTableViewControllerDelegate?
    private var service: AccountSettingsService?
    private var suggestions: [String] = []
    private var isSearching: Bool = false
    private var selectedCell: UITableViewCell?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.register(UINib(nibName: "SiteCreationDomainSearchTableViewCell", bundle: nil), forCellReuseIdentifier: SiteCreationDomainSearchTableViewCell.cellIdentifier)
        setupBackgroundTapGestureRecognizer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.layoutMargins = WPStyleGuide.edgeInsetForLoginTextFields()

        navigationItem.title = NSLocalizedString("Pick username", comment: "Title for selecting a new username in the site creation flow.")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // only procede with initial search if we don't have site title suggestions yet (hopefully only the first time)
        guard suggestions.count < 1,
            let nameToSearch = displayName else {
                return
        }

        suggestUsernames(for: nameToSearch) { [weak self] (suggestions) in
            self?.suggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integersIn: Sections.searchField.rawValue...Sections.suggestions.rawValue), with: .automatic)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }

    private func suggestUsernames(for searchTerm: String, addSuggestions: @escaping ([String]) ->()) {
        guard !isSearching else {
            return
        }

        isSearching = true

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.defaultWordPressComAccount(),
            let api = account.wordPressComRestApi else {
            return
        }
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading usernames", comment: "Shown while the app waits for the username suggestions web service to return during the site creation process."))

        let service = AccountSettingsService(userID: account.userID.intValue, api: api)
        service.suggestUsernames(base: searchTerm) { [weak self] (newSuggestions) in
            self?.isSearching = false
            SVProgressHUD.dismiss()
            addSuggestions(newSuggestions)
        }
    }

    func setupBackgroundTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on(call: { [weak self] (gesture) in
            self?.view.endEditing(true)
        })
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }
}

// MARK: UITableViewDataSource

extension SignupUsernameTableViewController {
    fileprivate enum Sections: Int {
        case titleAndDescription = 0
        case searchField = 1
        case suggestions = 2

        static var count: Int {
            return suggestions.rawValue + 1
        }
    }

    private enum SuggestionStyles {
        static let indentationWidth: CGFloat = 20.0
        static let indentationLevel = 1
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.titleAndDescription.rawValue:
            return 1
        case Sections.searchField.rawValue:
            return suggestions.count > 0 ? 1 : 0
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
        case Sections.searchField.rawValue:
            cell = searchFieldCell()
        case Sections.suggestions.rawValue:
            fallthrough
        default:
            let suggestion = suggestions[indexPath.row]
            cell = suggestionCell(username: suggestion)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Sections.suggestions.rawValue {
            let footer = UIView()
            footer.backgroundColor = WPStyleGuide.greyLighten20()
            return footer
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == Sections.suggestions.rawValue {
            return 0.5
        }
        return 0
    }

    // MARK: table view cells

    private func titleAndDescriptionCell() -> UITableViewCell {
        let description = String(format: NSLocalizedString("Your username is currently \"%@\". It will be used for mentions and links, but otherwise people will just see your display name, \"%@\"", comment: "Description of how to pick a domain name during the site creation process"), currentUsername ?? "", displayName ?? "")
        let cell = LoginSocialErrorCell(title: "", description: description)
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

    private func suggestionCell(username: String) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.textLabel?.text = username
        cell.textLabel?.textColor = WPStyleGuide.darkGrey()
        cell.indentationWidth = SuggestionStyles.indentationWidth
        cell.indentationLevel = SuggestionStyles.indentationLevel
        return cell
    }
}

extension SignupUsernameTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUsername: String
        switch indexPath.section {
        case Sections.suggestions.rawValue:
            selectedUsername = suggestions[indexPath.row]
        default:
            return
        }
        delegate?.usernameSelected(selectedUsername)

        tableView.deselectSelectedRowWithAnimation(true)

        // Uncheck the previously selected cell.
        if let selectedCell = selectedCell {
            selectedCell.accessoryType = .none
        }

        // Check the currently selected cell.
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            selectedCell = cell
        }
    }
}


// MARK: SiteCreationDomainSearchTableViewCellDelegate

extension SignupUsernameTableViewController: SiteCreationDomainSearchTableViewCellDelegate {
    func startSearch(for searchTerm: String) {

        delegate?.newSearchStarted()

        guard searchTerm.count > 0 else {
            return
        }

        suggestUsernames(for: searchTerm) { [weak self] (suggestions) in
            self?.suggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integer: Sections.suggestions.rawValue), with: .automatic)
        }
    }
}
