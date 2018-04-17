import UIKit
import SVProgressHUD

protocol SiteCreationDomainsTableViewControllerDelegate {
    func domainSelected(_ domain: String)
    func newSearchStarted()
}

class SiteCreationDomainsTableViewController: NUXTableViewController {

    // MARK: - Properties

    open var siteName: String?
    open var delegate: SiteCreationDomainsTableViewControllerDelegate?

    private var noResultsViewController: NoResultsViewController?
    private var service: DomainsService?
    private var siteTitleSuggestions: [String] = []
    private var searchSuggestions: [String] = []
    private var isSearching: Bool = false
    private var selectedCell: UITableViewCell?

    // API returned no domain suggestions.
    private var noSuggestions: Bool = false

    fileprivate enum ViewPadding: CGFloat {
        case noResultsView = 60
    }

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.register(UINib(nibName: "SearchTableViewCell", bundle: nil), forCellReuseIdentifier: SearchTableViewCell.reuseIdentifier)
        setupBackgroundTapGestureRecognizer()
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.layoutMargins = WPStyleGuide.edgeInsetForLoginTextFields()

        navigationItem.title = NSLocalizedString("Create New Site", comment: "Title for the site creation flow.")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // only procede with initial search if we don't have site title suggestions yet
        // (hopefully only the first time)
        guard siteTitleSuggestions.count < 1,
            let nameToSearch = siteName else {
            return
        }

        suggestDomains(for: nameToSearch) { [weak self] (suggestions) in
            self?.siteTitleSuggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integer: Sections.suggestions.rawValue), with: .automatic)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }

    /// Fetches new domain suggestions based on the provided string
    ///
    /// - Parameters:
    ///   - searchTerm: string to base suggestions on
    ///   - addSuggestions: function to call when results arrive
    private func suggestDomains(for searchTerm: String, addSuggestions: @escaping (_: [String]) ->()) {
        guard !isSearching else {
            return
        }

        isSearching = true

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let api = accountService.defaultWordPressComAccount()?.wordPressComRestApi ?? WordPressComRestApi(oAuthToken: "")

        let service = DomainsService(managedObjectContext: ContextManager.sharedInstance().mainContext, remote: DomainsServiceRemote(wordPressComRestApi: api))
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading domains", comment: "Shown while the app waits for the domain suggestions web service to return during the site creation process."))

        service.getDomainSuggestions(base: searchTerm, success: { [weak self] (suggestions) in
            self?.isSearching = false
            self?.noSuggestions = false
            SVProgressHUD.dismiss()
            self?.tableView.separatorStyle = .singleLine
            // Dismiss the keyboard so the full results list can be seen.
            self?.view.endEditing(true)
            addSuggestions(suggestions)
        }) { [weak self] (error) in
            DDLogError("Error getting Domain Suggestions: \(error.localizedDescription)")
            self?.isSearching = false
            self?.noSuggestions = true
            SVProgressHUD.dismiss()
            self?.tableView.separatorStyle = .none
            // Dismiss the keyboard so the full no results view can be seen.
            self?.view.endEditing(true)
            // Add no suggestions to display the no results view.
            addSuggestions([])
        }
    }

    // MARK: background gesture recognizer

    /// Sets up a gesture recognizer to detect taps on the view, but not its content.
    ///
    func setupBackgroundTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on { [weak self](gesture) in
            self?.view.endEditing(true)
        }
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }
}

// MARK: - UITableViewDataSource

extension SiteCreationDomainsTableViewController {
    fileprivate enum Sections: Int {
        case titleAndDescription = 0
        case searchField = 1
        case suggestions = 2

        static var count: Int {
            return suggestions.rawValue + 1
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.titleAndDescription.rawValue,
             Sections.searchField.rawValue:
            return 1
        case Sections.suggestions.rawValue:
            if noSuggestions == true {
                return 1
            }
            return searchSuggestions.count > 0 ? searchSuggestions.count : siteTitleSuggestions.count
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
            if noSuggestions == true {
                cell = noResultsCell()
            } else {
                let suggestion: String
                if searchSuggestions.count > 0 {
                    suggestion = searchSuggestions[indexPath.row]
                } else {
                    suggestion = siteTitleSuggestions[indexPath.row]
                }
                cell = suggestionCell(domain: suggestion)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.section == Sections.suggestions.rawValue && noSuggestions == true {
            // Calculate the height of the no results cell from the bottom of
            // the search field to the screen bottom, minus some padding.
            let searchFieldRect = tableView.rect(forSection: Sections.searchField.rawValue)
            let searchFieldBottom = searchFieldRect.origin.y + searchFieldRect.height
            let screenBottom = UIScreen.main.bounds.height
            return screenBottom - searchFieldBottom - ViewPadding.noResultsView.rawValue
        }

        return super.tableView(tableView, heightForRowAt: indexPath)
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
        let title = NSLocalizedString("Step 4 of 4", comment: "Title for last step in the site creation process.").localizedUppercase
        let description = NSLocalizedString("Pick an available \"yourname.wordpress.com\" address to let people find you on the web.", comment: "Description of how to pick a domain name during the site creation process")
        let cell = LoginSocialErrorCell(title: title, description: description)
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

    private func noResultsCell() -> UITableViewCell {
        let cell = UITableViewCell()
        addNoResultsTo(cell: cell)
        cell.isUserInteractionEnabled = false
        return cell
    }

    private func suggestionCell(domain: String) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.textLabel?.attributedText = styleDomain(domain)
        cell.textLabel?.textColor = WPStyleGuide.grey()
        cell.indentationWidth = 20.0
        cell.indentationLevel = 1
        return cell
    }

    private func styleDomain(_ domain: String) -> NSAttributedString {
        let styledDomain: NSMutableAttributedString = NSMutableAttributedString(string: domain)
        guard let dotPosition = domain.index(of: ".") else {
            return styledDomain
        }
        styledDomain.addAttribute(.foregroundColor, value: WPStyleGuide.darkGrey(), range: NSMakeRange(0, dotPosition.encodedOffset))
        return styledDomain
    }
}

// MARK: - NoResultsViewController Extension

private extension SiteCreationDomainsTableViewController {

    func addNoResultsTo(cell: UITableViewCell) {
        if noResultsViewController == nil {
            instantiateNoResultsViewController()
        }

        guard let noResultsViewController = noResultsViewController else {
            return
        }

        noResultsViewController.view.frame = cell.frame
        cell.contentView.addSubview(noResultsViewController.view)

        addChildViewController(noResultsViewController)
        noResultsViewController.didMove(toParentViewController: self)
    }

    func removeNoResultsFromView() {
        noSuggestions = false
        tableView.reloadSections(IndexSet(integer: Sections.suggestions.rawValue), with: .automatic)
        noResultsViewController?.view.removeFromSuperview()
        noResultsViewController?.removeFromParentViewController()
    }

    func instantiateNoResultsViewController() {
        let noResultsSB = UIStoryboard(name: "NoResults", bundle: nil)
        noResultsViewController = noResultsSB.instantiateViewController(withIdentifier: "NoResults") as? NoResultsViewController

        let title = NSLocalizedString("We couldn't find any available address with the words you entered - let's try again.", comment: "Primary message shown when there are no domains that match the user entered text.")
        let subtitle = NSLocalizedString("Enter different words above and we'll look for an address that matches it.", comment: "Secondary message shown when there are no domains that match the user entered text.")

        noResultsViewController?.configure(title: title, buttonTitle: nil, subtitle: subtitle)
    }

}

// MARK: - UITableViewDelegate

extension SiteCreationDomainsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedDomain: String
        switch indexPath.section {
        case Sections.suggestions.rawValue:
            if searchSuggestions.count > 0 {
                selectedDomain = searchSuggestions[indexPath.row]
            } else {
                selectedDomain = siteTitleSuggestions[indexPath.row]
            }
        default:
            return
        }

        // Remove ".wordpress.com" before sending it to the delegate
        selectedDomain = selectedDomain.components(separatedBy: ".")[0]
        delegate?.domainSelected(selectedDomain)

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

// MARK: - SearchTableViewCellDelegate

extension SiteCreationDomainsTableViewController: SearchTableViewCellDelegate {
    func startSearch(for searchTerm: String) {

        removeNoResultsFromView()
        delegate?.newSearchStarted()

        guard searchTerm.count > 0 else {
            searchSuggestions = []
            tableView.reloadSections(IndexSet(integer: Sections.suggestions.rawValue), with: .automatic)
            return
        }

        suggestDomains(for: searchTerm) { [weak self] (suggestions) in
            self?.searchSuggestions = suggestions
            self?.tableView.reloadSections(IndexSet(integer: Sections.suggestions.rawValue), with: .automatic)
        }
    }
}
