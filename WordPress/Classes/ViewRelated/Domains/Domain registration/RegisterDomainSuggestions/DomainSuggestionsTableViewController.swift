import UIKit
import SVProgressHUD
import WordPressAuthenticator


protocol DomainSuggestionsTableViewControllerDelegate {
    func domainSelected(_ domain: FullyQuotedDomainSuggestion)
    func newSearchStarted()
}

/// This class provides domain suggestions based on keyword searches
/// performed by the user.
///
class DomainSuggestionsTableViewController: UITableViewController {

    // MARK: - Fonts

    private let domainBaseFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
    private let domainTLDFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
    private let saleCostFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
    private let suggestionCostFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
    private let perYearPostfixFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
    private let freeForFirstYearFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)

    // MARK: - Cell Identifiers

    private static let suggestionCellIdentifier = "org.wordpress.domainsuggestionstable.suggestioncell"

    // MARK: - Properties

    var blog: Blog?
    var siteName: String?
    var delegate: DomainSuggestionsTableViewControllerDelegate?
    var domainSuggestionType: DomainsServiceRemote.DomainSuggestionType = .noWordpressDotCom
    var domainType: DomainType?
    var freeSiteAddress: String = ""

    var useFadedColorForParentDomains: Bool {
        return false
    }

    var searchFieldPlaceholder: String {
        return NSLocalizedString(
            "Type to get more suggestions",
            comment: "Register domain - Search field placeholder for the Suggested Domain screen"
        )
    }

    private var noResultsViewController: NoResultsViewController?
    private var siteTitleSuggestions: [FullyQuotedDomainSuggestion] = []
    private var searchSuggestions: [FullyQuotedDomainSuggestion] = [] {
        didSet {
            tableView.reloadSections(IndexSet(integer: Sections.suggestions.rawValue), with: .automatic)
        }
    }
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

    private let searchDebouncer = Debouncer(delay: 0.5)

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
    private func suggestDomains(for searchTerm: String, addSuggestions: @escaping (_: [FullyQuotedDomainSuggestion]) ->()) {
        guard !isSearching else {
            return
        }

        isSearching = true

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let api = accountService.defaultWordPressComAccount()?.wordPressComRestApi ?? WordPressComRestApi.defaultApi(oAuthToken: "")

        let service = DomainsService(managedObjectContext: ContextManager.sharedInstance().mainContext, remote: DomainsServiceRemote(wordPressComRestApi: api))

        SVProgressHUD.setContainerView(tableView)
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading domains", comment: "Shown while the app waits for the domain suggestions web service to return during the site creation process."))

        service.getFullyQuotedDomainSuggestions(query: searchTerm,
                                                domainSuggestionType: domainSuggestionType,
                                                success: handleGetDomainSuggestionsSuccess,
                                                failure: handleGetDomainSuggestionsFailure)
    }

    private func handleGetDomainSuggestionsSuccess(_ suggestions: [FullyQuotedDomainSuggestion]) {
        isSearching = false
        noSuggestions = false
        SVProgressHUD.dismiss()
        tableView.separatorStyle = .singleLine

        searchSuggestions = suggestions
    }

    private func handleGetDomainSuggestionsFailure(_ error: Error) {
        DDLogError("Error getting Domain Suggestions: \(error.localizedDescription)")
        isSearching = false
        noSuggestions = true
        SVProgressHUD.dismiss()
        tableView.separatorStyle = .none

        // Dismiss the keyboard so the full no results view can be seen.
        view.endEditing(true)

        // Add no suggestions to display the no results view.
        searchSuggestions = []
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
    fileprivate enum Sections: Int, CaseIterable {
        case topBanner
        case searchField
        case suggestions

        static var count: Int {
            return allCases.count
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.topBanner.rawValue:
            return shouldShowTopBanner ? 1 : 0
        case Sections.searchField.rawValue:
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
        case Sections.topBanner.rawValue:
            cell = topBannerCell()
        case Sections.searchField.rawValue:
            cell = searchFieldCell()
        case Sections.suggestions.rawValue:
            fallthrough
        default:
            if noSuggestions == true {
                cell = noResultsCell()
            } else {
                let suggestion: FullyQuotedDomainSuggestion
                if searchSuggestions.count > 0 {
                    suggestion = searchSuggestions[indexPath.row]
                } else {
                    suggestion = siteTitleSuggestions[indexPath.row]
                }
                cell = suggestionCell(suggestion)
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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == Sections.searchField.rawValue {
            let header = UIView()
            header.backgroundColor = tableView.backgroundColor
            return header
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Sections.searchField.rawValue {
            return 10
        }
        return 0
    }

    // MARK: table view cells

    private func topBannerCell() -> UITableViewCell {
        let cell = UITableViewCell()
        guard let textLabel = cell.textLabel else {
            return cell
        }

        textLabel.font = UIFont.preferredFont(forTextStyle: .body)
        textLabel.numberOfLines = 3
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.5

        let template = NSLocalizedString("Domains purchased on this site will redirect to %@", comment: "Description for the first domain purchased with a free plan.")
        let formatted = String(format: template, freeSiteAddress)
        let attributed = NSMutableAttributedString(string: formatted, attributes: [:])

        if let range = formatted.range(of: freeSiteAddress) {
            attributed.addAttributes([.font: textLabel.font.bold()], range: NSRange(range, in: formatted))
        }

        textLabel.attributedText = attributed

        return cell
    }

    private var shouldShowTopBanner: Bool {
        if let domainType = domainType,
           domainType == .siteRedirect {
            return true
        }

        return false
    }

    private func searchFieldCell() -> SearchTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchTableViewCell.reuseIdentifier) as? SearchTableViewCell else {
            fatalError()
        }

        cell.allowSpaces = false
        cell.liveSearch = true
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

    // MARK: - Suggestion Cell

    private func suggestionCell(_ suggestion: FullyQuotedDomainSuggestion) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Self.suggestionCellIdentifier)

        cell.textLabel?.attributedText = attributedDomain(suggestion.domainName)
        cell.textLabel?.textColor = parentDomainColor
        cell.indentationWidth = 20.0
        cell.indentationLevel = 1

        if Feature.enabled(.domains) {
            cell.detailTextLabel?.attributedText = attributedCostInformation(for: suggestion)
        }

        return cell
    }

    private func attributedDomain(_ domain: String) -> NSAttributedString {
        let attributedDomain = NSMutableAttributedString(string: domain, attributes: [.font: domainBaseFont])

        guard let dotPosition = domain.firstIndex(of: ".") else {
            return attributedDomain
        }

        let tldRange = dotPosition ..< domain.endIndex
        let nsRange = NSRange(tldRange, in: domain)

        attributedDomain.addAttribute(.font,
                                      value: domainTLDFont,
                                      range: nsRange)

        return attributedDomain
    }

    private func attributedCostInformation(for suggestion: FullyQuotedDomainSuggestion) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()

        let hasDomainCredit = blog?.hasDomainCredit ?? false

        if hasDomainCredit {
            attributedString.append(attributedFreeForTheFirstYear())
        } else if let saleCost = attributedSaleCost(for: suggestion) {
            attributedString.append(saleCost)
        }

        attributedString.append(attributedSuggestionCost(for: suggestion, hasDomainCredit: hasDomainCredit))
        attributedString.append(attributedPerYearPostfix(for: suggestion, hasDomainCredit: hasDomainCredit))

        return attributedString
    }

    // MARK: - Attributed partial strings

    private func attributedFreeForTheFirstYear() -> NSAttributedString {
        NSAttributedString(
            string: NSLocalizedString("Free for the first year ", comment: "Label shown for domains that will be free for the first year due to the user having a premium plan with available domain credit."),
            attributes: [.font: freeForFirstYearFont, .foregroundColor: UIColor.muriel(name: .green, .shade50)])
    }

    private func attributedSaleCost(for suggestion: FullyQuotedDomainSuggestion) -> NSAttributedString? {
        guard let saleCostString = suggestion.saleCostString else {
            return nil
        }

        return NSAttributedString(
            string: saleCostString + " ",
            attributes: suggestionSaleCostAttributes())
    }

    private func attributedSuggestionCost(for suggestion: FullyQuotedDomainSuggestion, hasDomainCredit: Bool) -> NSAttributedString {
        NSAttributedString(
            string: suggestion.costString,
            attributes: suggestionCostAttributes(striked: mustStrikeRegularPrice(suggestion, hasDomainCredit: hasDomainCredit)))
    }

    private func attributedPerYearPostfix(for suggestion: FullyQuotedDomainSuggestion, hasDomainCredit: Bool) -> NSAttributedString {
        NSAttributedString(
            string: NSLocalizedString(" / year", comment: "Per-year postfix shown after a domain's cost."),
            attributes: perYearPostfixAttributes(striked: mustStrikeRegularPrice(suggestion, hasDomainCredit: hasDomainCredit)))
    }

    // MARK: - Attributed partial string attributes

    private func mustStrikeRegularPrice(_ suggestion: FullyQuotedDomainSuggestion, hasDomainCredit: Bool) -> Bool {
        suggestion.saleCostString != nil || hasDomainCredit
    }

    private func suggestionSaleCostAttributes() -> [NSAttributedString.Key: Any] {
        [.font: suggestionCostFont,
         .foregroundColor: UIColor.muriel(name: .orange, .shade50)]
    }

    private func suggestionCostAttributes(striked: Bool) -> [NSAttributedString.Key: Any] {
        [.font: suggestionCostFont,
         .foregroundColor: striked ? UIColor.secondaryLabel : UIColor.label,
         .strikethroughStyle: striked ? 1 : 0]
    }

    private func perYearPostfixAttributes(striked: Bool) -> [NSAttributedString.Key: Any] {
        [.font: perYearPostfixFont,
         .foregroundColor: UIColor.secondaryLabel,
         .strikethroughStyle: striked ? 1 : 0]
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
        let selectedDomain: FullyQuotedDomainSuggestion

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
        searchDebouncer.call { [weak self] in
            self?.search(for: searchTerm)
        }
    }

    private func search(for searchTerm: String) {
        removeNoResultsFromView()
        delegate?.newSearchStarted()

        guard searchTerm.count > 0 else {
            searchSuggestions = []
            return
        }

        suggestDomains(for: searchTerm) { [weak self] (suggestions) in
            self?.searchSuggestions = suggestions
        }
    }
}

extension SearchTableViewCell {
    fileprivate func reloadTextfieldStyle() {
        textField.textColor = .text
        textField.leftViewImage = UIImage(named: "icon-post-search")
    }
}
