import UIKit
import SVProgressHUD
import WordPressAuthenticator


protocol DomainSuggestionsTableViewControllerDelegate {
    func domainSelected(_ domain: DomainSuggestion)
    func newSearchStarted()
}

/// This is intended to be an abstract base class that provides domain
/// suggestions for the keyword that user searches.
/// Subclasses should override the open variables to make customizations.
class DomainSuggestionsTableViewController: NUXTableViewController {

    // MARK: - Properties

    open var siteName: String?
    open var delegate: DomainSuggestionsTableViewControllerDelegate?
    open var domainSuggestionType: DomainsServiceRemote.DomainSuggestionType = .onlyWordPressDotCom

    open var useFadedColorForParentDomains: Bool {
        return true
    }
    open var sectionTitle: String {
        return ""
    }
    open var sectionDescription: String {
        return ""
    }
    open var searchFieldPlaceholder: String {
        return ""
    }

    private var noResultsViewController: NoResultsViewController?
    private var service: DomainsService?
    private var siteTitleSuggestions: [DomainSuggestion] = []
    private var searchSuggestions: [DomainSuggestion] = []
    private var isSearching: Bool = false
    private var selectedCell: UITableViewCell?

    // API returned no domain suggestions.
    private var noSuggestions: Bool = false

    fileprivate enum ViewPadding: CGFloat {
        case noResultsView = 60
    }

    private var parentDomainColor: UIColor {
        return useFadedColorForParentDomains ? .neutral(.shade30) : .neutral(.shade70)
    }

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let bundle = WordPressAuthenticator.bundle
        tableView.register(UINib(nibName: "SearchTableViewCell", bundle: bundle), forCellReuseIdentifier: SearchTableViewCell.reuseIdentifier)
        setupBackgroundTapGestureRecognizer()
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                tableView.reloadData()
            }
        }
    }

    /// Fetches new domain suggestions based on the provided string
    ///
    /// - Parameters:
    ///   - searchTerm: string to base suggestions on
    ///   - addSuggestions: function to call when results arrive
    private func suggestDomains(for searchTerm: String, addSuggestions: @escaping (_: [DomainSuggestion]) ->()) {
        guard !isSearching else {
            return
        }

        isSearching = true

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let api = accountService.defaultWordPressComAccount()?.wordPressComRestApi ?? WordPressComRestApi.defaultApi(oAuthToken: "")

        let service = DomainsService(managedObjectContext: ContextManager.sharedInstance().mainContext, remote: DomainsServiceRemote(wordPressComRestApi: api))
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading domains", comment: "Shown while the app waits for the domain suggestions web service to return during the site creation process."))

        service.getDomainSuggestions(base: searchTerm,
                                     domainSuggestionType: domainSuggestionType,
                                     success: { [weak self] (suggestions) in
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

extension DomainSuggestionsTableViewController {
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
                    suggestion = searchSuggestions[indexPath.row].domainName
                } else {
                    suggestion = siteTitleSuggestions[indexPath.row].domainName
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

    @objc func titleAndDescriptionCell() -> UITableViewCell {
        let cell = LoginSocialErrorCell(title: sectionTitle,
                                        description: sectionDescription)
        cell.selectionStyle = .none
        return cell
    }

    private func searchFieldCell() -> SearchTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchTableViewCell.reuseIdentifier) as? SearchTableViewCell else {
            fatalError()
        }

        cell.placeholder = searchFieldPlaceholder
        cell.reloadTextfieldStyle()
        cell.delegate = self
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
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
        cell.textLabel?.textColor = parentDomainColor
        cell.indentationWidth = 20.0
        cell.indentationLevel = 1
        return cell
    }

    private func styleDomain(_ domain: String) -> NSAttributedString {
        let styledDomain: NSMutableAttributedString = NSMutableAttributedString(string: domain)
        guard let dotPosition = domain.index(of: ".") else {
            return styledDomain
        }
        styledDomain.addAttribute(.foregroundColor,
                                  value: UIColor.neutral(.shade70),
                                  range: NSMakeRange(0, dotPosition.utf16Offset(in: domain)))
        return styledDomain
    }
}

// MARK: - NoResultsViewController Extension

private extension DomainSuggestionsTableViewController {

    func addNoResultsTo(cell: UITableViewCell) {
        if noResultsViewController == nil {
            instantiateNoResultsViewController()
        }

        guard let noResultsViewController = noResultsViewController else {
            return
        }

        noResultsViewController.view.frame = cell.frame
        cell.contentView.addSubview(noResultsViewController.view)

        addChild(noResultsViewController)
        noResultsViewController.didMove(toParent: self)
    }

    func removeNoResultsFromView() {
        noSuggestions = false
        tableView.reloadSections(IndexSet(integer: Sections.suggestions.rawValue), with: .automatic)
        noResultsViewController?.removeFromView()
    }

    func instantiateNoResultsViewController() {
        let title = NSLocalizedString("We couldn't find any available address with the words you entered - let's try again.", comment: "Primary message shown when there are no domains that match the user entered text.")
        let subtitle = NSLocalizedString("Enter different words above and we'll look for an address that matches it.", comment: "Secondary message shown when there are no domains that match the user entered text.")

        noResultsViewController = NoResultsViewController.controllerWith(title: title, buttonTitle: nil, subtitle: subtitle)
    }

}

// MARK: - UITableViewDelegate

extension DomainSuggestionsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDomain: DomainSuggestion

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

extension DomainSuggestionsTableViewController: SearchTableViewCellDelegate {
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

extension SearchTableViewCell {
    fileprivate func reloadTextfieldStyle() {
        textField.textColor = .text
        textField.leftViewImage = UIImage(named: "icon-post-search")
    }
}
