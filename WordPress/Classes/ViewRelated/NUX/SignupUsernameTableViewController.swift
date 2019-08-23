import SVProgressHUD
import WordPressAuthenticator


class SignupUsernameTableViewController: NUXTableViewController, SearchTableViewCellDelegate {
    open var currentUsername: String?
    open var displayName: String?
    open var delegate: SignupUsernameViewControllerDelegate?
    open var suggestions: [String] = []
    private var service: AccountSettingsService?
    private var isSearching: Bool = false
    private var selectedCell: UITableViewCell?

    override func awakeFromNib() {
        super.awakeFromNib()

        registerNibs()
        setupBackgroundTapGestureRecognizer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
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
            self?.reloadSections()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }

    func registerNibs() {
        let bundle = WordPressAuthenticator.bundle
        tableView.register(UINib(nibName: "SearchTableViewCell", bundle: bundle), forCellReuseIdentifier: SearchTableViewCell.reuseIdentifier)
    }

    func reloadSections(includingAllSections: Bool = true) {
        DispatchQueue.main.async {
            let set = includingAllSections ? IndexSet(integersIn: Sections.searchField.rawValue...Sections.suggestions.rawValue) : IndexSet(integer: Sections.suggestions.rawValue)
            self.tableView.reloadSections(set, with: .automatic)
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

    func buildHeaderDescription() -> NSAttributedString {
        guard let currentUsername = currentUsername, let displayName = displayName else {
            return NSAttributedString(string: "")
        }

        let baseDescription = String(format: NSLocalizedString("Your current username is %@. With few exceptions, others will only ever see your display name, %@.", comment: "Instructional text that displays the current username and display name."), currentUsername, displayName)
        guard let rangeOfUsername = baseDescription.range(of: currentUsername),
            let rangeOfDisplayName = baseDescription.range(of: displayName) else {
                return NSAttributedString(string: baseDescription)
        }
        let boldFont = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        let plainFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let description = NSMutableAttributedString(string: baseDescription, attributes: [.font: plainFont])
        description.addAttribute(.font, value: boldFont, range: baseDescription.nsRange(from: rangeOfUsername))
        description.addAttribute(.font, value: boldFont, range: baseDescription.nsRange(from: rangeOfDisplayName))
        return description
    }

    // MARK: - SearchTableViewCellDelegate

    func startSearch(for searchTerm: String) {
        guard searchTerm.count > 0 else {
            return
        }

        suggestUsernames(for: searchTerm) { [weak self] suggestions in
            self?.suggestions = suggestions
            self?.reloadSections(includingAllSections: false)
        }
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
            return 1
        case Sections.suggestions.rawValue:
            return suggestions.count + 1
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
            if indexPath.row == 0 {
                cell = suggestionCell(username: currentUsername ?? "username not found", checked: true)
                selectedCell = cell
            } else {
                cell = suggestionCell(username: suggestions[indexPath.row - 1], checked: false)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Sections.suggestions.rawValue {
            let footer = UIView()
            footer.backgroundColor = .neutral(.shade10)
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
        let descriptionStyled = buildHeaderDescription()
        let cell = LoginSocialErrorCell(title: "", description: descriptionStyled)
        cell.selectionStyle = .none
        return cell
    }

    private func searchFieldCell() -> SearchTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchTableViewCell.reuseIdentifier) as? SearchTableViewCell else {
            fatalError()
        }

        cell.placeholder = NSLocalizedString("Type a keyword for more ideas", comment: "Placeholder text for domain search during site creation.")
        cell.delegate = self
        cell.selectionStyle = .none

        return cell
    }

    private func suggestionCell(username: String, checked: Bool) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.textLabel?.text = username
        cell.textLabel?.textColor = .neutral(.shade70)
        cell.indentationWidth = SuggestionStyles.indentationWidth
        cell.indentationLevel = SuggestionStyles.indentationLevel
        if checked {
            cell.accessoryType = .checkmark
        }
        return cell
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
            if newSuggestions.count == 0 {
                WordPressAuthenticator.track(.signupEpilogueUsernameSuggestionsFailed)
            }
            self?.isSearching = false
            SVProgressHUD.dismiss()
            addSuggestions(newSuggestions)
        }
    }
}

extension String {
    private func nsRange(from range: Range<Index>) -> NSRange {
        let from = range.lowerBound
        let to = range.upperBound

        let location = distance(from: startIndex, to: from)
        let length = distance(from: from, to: to)

        return NSRange(location: location, length: length)
    }
}

extension SignupUsernameTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUsername: String
        switch indexPath.section {
        case Sections.suggestions.rawValue:
            if indexPath.row == 0 {
                selectedUsername = currentUsername ?? ""
            } else {
                selectedUsername = suggestions[indexPath.row - 1]
            }
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
