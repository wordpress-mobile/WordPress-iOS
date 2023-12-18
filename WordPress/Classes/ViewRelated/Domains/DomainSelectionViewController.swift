import UIKit
import WordPressAuthenticator
import SwiftUI

/// Contains the UI corresponding to the list of Domain suggestions.
///
class DomainSelectionViewController: CollapsableHeaderViewController {
    static let noMatchCellReuseIdentifier = "noMatchCellReuseIdentifier"

    // MARK: Properties
    private struct Metrics {
        static let maxLabelWidth            = CGFloat(290)
        static let noResultsTopInset        = CGFloat(64)
        static let sitePromptEdgeMargin     = CGFloat(50)
        static let sitePromptBottomMargin   = CGFloat(10)
        static let sitePromptTopMargin      = CGFloat(4)
    }

    override var separatorStyle: SeparatorStyle {
        return .hidden
    }

    var domainPurchasingEnabled: Bool {
        return true
    }

    var information: String? {
        return nil
    }

    /// The creator collects user input as they advance through the wizard flow.
    private let service: SiteAddressService
    private let selection: (DomainSuggestion) -> Void

    /// Tracks the site address selected by users
    private var selectedDomain: DomainSuggestion? {
        didSet {
            if selectedDomain != nil {
                hideTransferFooterView()
            }
            itemSelectionChanged(selectedDomain != nil)
        }
    }

    /// The table view renders our server content
    private let table: UITableView
    private let searchHeader: UIView
    private let searchTextField: SearchTextField
    private let searchBar = UISearchBar()
    private var sitePromptView: SitePromptView!
    private let siteCreationEmptyTemplate = SiteCreationEmptySiteTemplate()
    private lazy var siteTemplateHostingController = UIHostingController(rootView: siteCreationEmptyTemplate)
    private let domainSelectionType: DomainSelectionType
    private var analyticsSource: String? // TODO

    /// The underlying data represented by the provider
    var data: [DomainSuggestion] {
        didSet {
            contentSizeWillChange()
            table.reloadData()
        }
    }
    private var _hasExactMatch: Bool = false
    var hasExactMatch: Bool {
        get {
            guard (lastSearchQuery ?? "").count > 0 else {
                // Forces the no match cell to hide when the results are empty.
                return true
            }
            // Return true if there is no data to supress the no match cell
            return data.count > 0 ? _hasExactMatch : true
        }
        set {
            _hasExactMatch = newValue
        }
    }

    /// The throttle meters requests to the remote service
    private let throttle = Scheduler(seconds: 0.5)

    /// We track the last searched value so that we can retry
    private var lastSearchQuery: String? = nil

    /// Locally tracks the network connection status via `NetworkStatusDelegate`
    private var isNetworkActive = ReachabilityUtils.isInternetReachable()

    /// This message is shown when there are no domain suggestions to list
    private let noResultsLabel: UILabel

    private var noResultsLabelTopAnchor: NSLayoutConstraint?
    private var isShowingError: Bool = false {
        didSet {
            if isShowingError {
                contentSizeWillChange()
                table.reloadData()
            }
        }
    }
    private var errorMessage: String {
        if isNetworkActive {
            return Strings.serverError
        } else {
            return Strings.noConnection
        }
    }

    // MARK: - Transfer Footer Views

    private lazy var transferFooterView: RegisterDomainTransferFooterView = {
        let configuration = RegisterDomainTransferFooterView.Configuration { [weak self] in
            guard let self else {
                return
            }
            let destination = TransferDomainsWebViewController(source: self.analyticsSource)
            self.present(UINavigationController(rootViewController: destination), animated: true)
        }
        return .init(configuration: configuration)
    }()

    /// Represents the layout constraints for the transfer footer view in its visible and hidden states.
    private lazy var transferFooterViewConstraints: (visible: [NSLayoutConstraint], hidden: [NSLayoutConstraint]) = {
        let base = [
            transferFooterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transferFooterView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]

        let visible = base + [transferFooterView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        let hidden = base + [transferFooterView.topAnchor.constraint(equalTo: view.bottomAnchor)]
        return (visible: visible, hidden: hidden)
    }()

    // MARK: WebAddressWizardContent

    init(
        service: SiteAddressService,
        domainSelectionType: DomainSelectionType,
        primaryActionTitle: String = Strings.selectDomain,
        selection: @escaping (DomainSuggestion) -> Void
    ) {
        self.service = service
        self.domainSelectionType = domainSelectionType
        self.selection = selection
        self.data = []
        self.noResultsLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.preferredMaxLayoutWidth = Metrics.maxLabelWidth

            label.font = WPStyleGuide.fontForTextStyle(.body)
            label.textAlignment = .center
            label.textColor = .text
            label.text = Strings.noResults

            label.sizeToFit()

            label.isHidden = true

            return label
        }()
        searchTextField = SearchTextField()
        searchHeader = UIView(frame: .zero)
        table = UITableView(frame: .zero, style: .grouped)
        super.init(scrollableView: table,
                   mainTitle: Strings.mainTitle,
                   prompt: Strings.prompt,
                   primaryActionTitle: primaryActionTitle,
                   accessoryView: searchHeader)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        WPAnalytics.track(.enhancedSiteCreationDomainsAccessed)
        loadHeaderView()
        addAddressHintView()
        configureUIIfNeeded()
        navigationItem.backButtonTitle = Strings.backButtonTitle
        setupTransferFooterView()
    }

    private func configureUIIfNeeded() {
        guard domainPurchasingEnabled else {
            return
        }

        NSLayoutConstraint.activate([
            largeTitleView.widthAnchor.constraint(equalTo: headerStackView.widthAnchor)
        ])
        largeTitleView.textAlignment = .center
        promptView.textAlignment = .center
        promptView.font = .systemFont(ofSize: 17)
    }

    private func loadHeaderView() {

        if domainPurchasingEnabled {
            searchBar.searchBarStyle = UISearchBar.Style.default
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            WPStyleGuide.configureSearchBar(searchBar, backgroundColor: .clear, returnKeyType: .search)
            searchBar.layer.borderWidth = 0
            searchHeader.addSubview(searchBar)
            searchBar.delegate = self
            headerView.backgroundColor = .basicBackground

            NSLayoutConstraint.activate([
                searchBar.leadingAnchor.constraint(equalTo: searchHeader.leadingAnchor, constant: 8),
                searchHeader.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: 8),
                searchBar.topAnchor.constraint(equalTo: searchHeader.topAnchor, constant: 1),
                searchHeader.bottomAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 1)
            ])
        } else {
            searchHeader.addSubview(searchTextField)
            searchHeader.backgroundColor = searchTextField.backgroundColor
            let top = NSLayoutConstraint(item: searchTextField, attribute: .top, relatedBy: .equal, toItem: searchHeader, attribute: .top, multiplier: 1, constant: 0)
            let bottom = NSLayoutConstraint(item: searchTextField, attribute: .bottom, relatedBy: .equal, toItem: searchHeader, attribute: .bottom, multiplier: 1, constant: 0)
            let leading = NSLayoutConstraint(item: searchTextField, attribute: .leading, relatedBy: .equal, toItem: searchHeader, attribute: .leadingMargin, multiplier: 1, constant: 0)
            let trailing = NSLayoutConstraint(item: searchTextField, attribute: .trailing, relatedBy: .equal, toItem: searchHeader, attribute: .trailingMargin, multiplier: 1, constant: 0)
            searchHeader.addConstraints([top, bottom, leading, trailing])
            searchHeader.addTopBorder(withColor: .divider)
            searchHeader.addBottomBorder(withColor: .divider)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeNetworkStatus()
        prepareViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restoreSearchIfNeeded()
        postScreenChangedForVoiceOver()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearContent()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        updateNoResultsLabelTopInset()

        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let self else { return }

            if self.domainPurchasingEnabled {
                if !self.siteTemplateHostingController.view.isHidden {
                    self.updateTitleViewVisibility(true)
                }
            } else {
                if !self.sitePromptView.isHidden {
                    self.updateTitleViewVisibility(true)
                }
            }
        }
    }

    override func estimatedContentSize() -> CGSize {
        guard !isShowingError else { return CGSize(width: view.frame.width, height: 44) }
        guard data.count > 0 else { return .zero }
        let estimatedSectionHeaderHeight: CGFloat = 85
        let cellCount = hasExactMatch ? data.count : data.count + 1
        let height = estimatedSectionHeaderHeight + (CGFloat(cellCount) * AddressTableViewCell.estimatedSize.height)
        return CGSize(width: view.frame.width, height: height)
    }

    // MARK: Private behavior
    private func clearContent() {
        throttle.cancel()
        itemSelectionChanged(false)
        data = []
        lastSearchQuery = nil
        setAddressHintVisibility(isHidden: false)
        noResultsLabel.isHidden = true
        expandHeader()
    }

    private func fetchAddresses(_ searchTerm: String) {
        isShowingError = false
        updateIcon(isLoading: true)

        let type: DomainsServiceRemote.DomainSuggestionType
        switch domainSelectionType {
        case .siteCreation:
            type = domainPurchasingEnabled ? .freeAndPaid : .wordPressDotComAndDotBlogSubdomains
        default:
            type = .noWordpressDotCom
//            if coordinator?.site?.hasBloggerPlan == true {
//                vc.domainSuggestionType = .allowlistedTopLevelDomains(["blog"])
//            }
        }

        service.addresses(for: searchTerm, type: type) { [weak self] results in
            DispatchQueue.main.async {
                self?.handleResult(results)
            }
        }
    }

    private func handleResult(_ results: Result<SiteAddressServiceResult, Error>) {
        updateIcon(isLoading: false)
        switch results {
        case .failure(let error):
            handleError(error)
        case .success(let data):
            hasExactMatch = data.hasExactMatch
            handleData(data.domainSuggestions, data.invalidQuery)
        }
    }

    private func handleData(_ data: [DomainSuggestion], _ invalidQuery: Bool) {
        let data = sortFreeAndPaidSuggestions(data)

        setAddressHintVisibility(isHidden: true)
        let resultsHavePreviousSelection = data.contains { (suggestion) -> Bool in self.selectedDomain?.domainName == suggestion.domainName }
        if !resultsHavePreviousSelection {
            clearSelectionAndCreateSiteButton()
        }

        self.data = data
        if data.isEmpty {
            if invalidQuery {
                noResultsLabel.text = Strings.invalidQuery
            } else {
                noResultsLabel.text = Strings.noResults
            }
            noResultsLabel.isHidden = false
        } else {
            noResultsLabel.isHidden = true
        }
        postSuggestionsUpdateAnnouncementForVoiceOver(listIsEmpty: data.isEmpty, invalidQuery: invalidQuery)
    }

    private func handleError(_ error: Error) {
        SiteCreationAnalyticsHelper.trackError(error)
        isShowingError = true
    }

    private func performSearchIfNeeded(query: String) {
        guard !query.isEmpty else {
            clearContent()
            return
        }

        lastSearchQuery = query

        guard isNetworkActive == true else {
            isShowingError = true
            return
        }

        throttle.debounce { [weak self] in
            guard let self = self else { return }
            self.fetchAddresses(query)
        }
    }

    override func primaryActionSelected(_ sender: Any) {
        guard let selectedDomain = selectedDomain else {
            return
        }

        trackDomainsSelection(selectedDomain)
        selection(selectedDomain)
    }

    private func setupCells() {
        let cellName = String(describing: AddressTableViewCell.self)
        table.register(AddressTableViewCell.self, forCellReuseIdentifier: cellName)
        table.register(InlineErrorRetryTableViewCell.self, forCellReuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
        table.cellLayoutMarginsFollowReadableWidth = true
    }

    private func restoreSearchIfNeeded() {
        if domainPurchasingEnabled {
            search(searchBar.text)
        } else {
            search(query(from: searchTextField))
        }
    }

    private func prepareViewIfNeeded() {
        searchTextField.becomeFirstResponder()
    }

    private func setupHeaderAndNoResultsMessage() {
        searchTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchTextField.delegate = self
        searchTextField.accessibilityTraits = .searchField

        let placeholderText = Strings.searchPlaceholder
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(.textPlaceholder)
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        searchTextField.attributedPlaceholder = attributedPlaceholder
        searchTextField.accessibilityHint = Strings.searchAccessibility

        view.addSubview(noResultsLabel)

        let noResultsLabelTopAnchor = noResultsLabel.topAnchor.constraint(equalTo: searchHeader.bottomAnchor)
        self.noResultsLabelTopAnchor = noResultsLabelTopAnchor

        NSLayoutConstraint.activate([
            noResultsLabel.widthAnchor.constraint(equalTo: table.widthAnchor, constant: -50),
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabelTopAnchor
        ])

        updateNoResultsLabelTopInset()
    }

    /// Sets the top inset for the noResultsLabel based on layout orientation
    private func updateNoResultsLabelTopInset() {
        noResultsLabelTopAnchor?.constant = UIDevice.current.orientation.isPortrait ? Metrics.noResultsTopInset : 0
    }

    private func setupTable() {
        if !domainPurchasingEnabled {
            table.separatorStyle = .none
        }
        table.dataSource = self
        table.estimatedRowHeight = AddressTableViewCell.estimatedSize.height
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupHeaderAndNoResultsMessage()
        table.showsVerticalScrollIndicator = false
        table.isAccessibilityElement = false
    }

    private func setupTableBackground() {
        table.backgroundColor = .basicBackground
    }

    private func setupTableSeparator() {
        table.separatorColor = .divider
        table.separatorInset.left = AddressTableViewCell.Appearance.contentMargins.leading
    }

    private func query(from textField: UITextField?) -> String? {
        guard let text = textField?.text,
              !text.isEmpty else {
            return information
        }

        return text
    }

    @objc
    private func textChanged(sender: UITextField) {
        search(sender.text)
    }

    private func clearSelectionAndCreateSiteButton() {
        selectedDomain = nil
        table.deselectSelectedRowWithAnimation(true)
        itemSelectionChanged(false)
    }

    private func trackDomainsSelection(_ domainSuggestion: DomainSuggestion) {
        var domainSuggestionProperties: [String: Any] = [
            "chosen_domain": domainSuggestion.domainName as AnyObject,
            "search_term": lastSearchQuery as AnyObject,
            "is_free": domainSuggestion.isFree.stringLiteral
        ]

        if domainPurchasingEnabled {
            domainSuggestionProperties["domain_cost"] = domainSuggestion.costString
        }

        WPAnalytics.track(.enhancedSiteCreationDomainsSelected, withProperties: domainSuggestionProperties)
    }

    // MARK: - Search logic

    func updateIcon(isLoading: Bool) {
        searchTextField.setIcon(isLoading: isLoading)
    }

    private func search(_ string: String?) {
        guard let query = string, query.isEmpty == false else {
            clearContent()
            showTransferFooterView()
            return
        }

        hideTransferFooterView()
        performSearchIfNeeded(query: query)
    }

    // MARK: - Search logic

    private func setAddressHintVisibility(isHidden: Bool) {
        if domainPurchasingEnabled {
            siteTemplateHostingController.view?.isHidden = isHidden
        } else {
            sitePromptView.isHidden = isHidden
        }
    }

    private func addAddressHintView() {
        if domainPurchasingEnabled {
            guard let siteCreationView = siteTemplateHostingController.view else {
                return
            }
            siteCreationView.isUserInteractionEnabled = false
            siteCreationView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(siteCreationView)
            NSLayoutConstraint.activate([
                siteCreationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                containerView.trailingAnchor.constraint(equalTo: siteCreationView.trailingAnchor, constant: 16),
                siteCreationView.topAnchor.constraint(equalTo: searchHeader.bottomAnchor, constant: Metrics.sitePromptTopMargin),
                containerView.bottomAnchor.constraint(equalTo: siteCreationView.bottomAnchor, constant: 0)
            ])
        } else {
            sitePromptView = SitePromptView(frame: .zero)
            sitePromptView.isUserInteractionEnabled = false
            sitePromptView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(sitePromptView)
            NSLayoutConstraint.activate([
                sitePromptView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Metrics.sitePromptEdgeMargin),
                sitePromptView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Metrics.sitePromptEdgeMargin),
                sitePromptView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: Metrics.sitePromptBottomMargin),
                sitePromptView.topAnchor.constraint(equalTo: searchHeader.bottomAnchor, constant: Metrics.sitePromptTopMargin)
            ])
        }
        setAddressHintVisibility(isHidden: true)
    }

    // MARK: - Others

    enum Strings {
        static let suggestionsUpdated = NSLocalizedString("Suggestions updated",
                                                          comment: "Announced by VoiceOver when new domains suggestions are shown in Site Creation.")
        static let noResults = NSLocalizedString("No available addresses matching your search",
                                                 comment: "Advises the user that no Domain suggestions could be found for the search query.")
        static let invalidQuery = NSLocalizedString("Your search includes characters not supported in WordPress.com domains. The following characters are allowed: A–Z, a–z, 0–9.",
                                                    comment: "This is shown to the user when their domain search query contains invalid characters.")
        static let noConnection: String = NSLocalizedString("No connection",
                                                            comment: "Displayed during Site Creation, when searching for Verticals and the network is unavailable.")
        static let serverError: String = NSLocalizedString("There was a problem",
                                                           comment: "Displayed during Site Creation, when searching for Verticals and the server returns an error.")
        static let mainTitle: String = NSLocalizedString("Choose a domain",
                                                         comment: "Select domain name. Title")
        static let prompt: String = NSLocalizedString("Search for a short and memorable keyword to help people find and visit your website.",
                                                      comment: "Select domain name. Subtitle")
        static let createSite: String = NSLocalizedString("Create Site",
                                                          comment: "Button to progress to the next step")
        static let selectDomain: String = NSLocalizedString("siteCreation.domains.buttons.selectDomain",
                                                            value: "Select domain",
                                                            comment: "Button to progress to the next step after selecting domain in Site Creation")
        static let searchPlaceholder: String = NSLocalizedString("Type a name for your site",
                                                                 comment: "Site creation. Seelect a domain, search field placeholder")
        static let searchAccessibility: String = NSLocalizedString("Searches for available domains to use for your site.",
                                                                   comment: "Accessibility hint for the domains search field in Site Creation.")
        static let suggestions: String = NSLocalizedString("Suggestions",
                                                           comment: "Suggested domains")
        static let noMatch: String = NSLocalizedString("This domain is unavailable",
                                                       comment: "Notifies the user that the a domain matching the search term wasn't returned in the results")
        static let backButtonTitle = NSLocalizedString("siteCreation.domain.backButton.title",
                                                       value: "Domains",
                                                       comment: "Back button title shown in Site Creation flow to come back from Plan selection to Domain selection"
        )
    }
}

// MARK: - Sorting

private extension DomainSelectionViewController {
    // Mimics the sorting on the web - two top domains, one free domain, and other domains
    private func sortFreeAndPaidSuggestions(_ suggestions: [DomainSuggestion]) -> [DomainSuggestion] {
        var topDomains: [DomainSuggestion] = []
        var freeDomains: [DomainSuggestion] = []
        var otherDomains: [DomainSuggestion] = []

        for i in 0..<suggestions.count {
            let suggestion = suggestions[i]
            if freeDomains.isEmpty && suggestion.isFree {
                freeDomains.append(suggestion)
                continue
            }

            if topDomains.count < 2 && !suggestion.isFree {
                topDomains.append(suggestion)
                continue
            }

            otherDomains.append(suggestion)
        }

        return topDomains + freeDomains + otherDomains
    }
}

// MARK: - NetworkStatusDelegate

extension DomainSelectionViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        isNetworkActive = active
    }
}

// MARK: - UITextFieldDelegate

extension DomainSelectionViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        clearSelectionAndCreateSiteButton()
        return true
    }
}

// MARK: - UISearchBarDelegate

extension DomainSelectionViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        clearSelectionAndCreateSiteButton()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(searchText)
    }
}

// MARK: - VoiceOver

private extension DomainSelectionViewController {
    func postScreenChangedForVoiceOver() {
        UIAccessibility.post(notification: .screenChanged, argument: table.tableHeaderView)
    }

    func postSuggestionsUpdateAnnouncementForVoiceOver(listIsEmpty: Bool, invalidQuery: Bool) {
        var message: String
        if listIsEmpty {
            message = invalidQuery ? Strings.invalidQuery : Strings.noResults
        } else {
            message = Strings.suggestionsUpdated
        }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// MARK: UITableViewDataSource
extension DomainSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isShowingError else { return 1 }
        return (!domainPurchasingEnabled && !hasExactMatch && section == 0) ? 1 : data.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard data.count > 0 else { return nil }
        return (!domainPurchasingEnabled && !hasExactMatch && section == 0) ? nil : Strings.suggestions
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (!domainPurchasingEnabled && !hasExactMatch && indexPath.section == 0) ? 60 : UITableView.automaticDimension
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return (domainPurchasingEnabled || hasExactMatch) ? 1 : 2
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return (!domainPurchasingEnabled && !hasExactMatch && section == 0) ? UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 3)) : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowingError {
            return configureErrorCell(tableView, cellForRowAt: indexPath)
        } else if !domainPurchasingEnabled && !hasExactMatch && indexPath.section == 0 {
            return configureNoMatchCell(table, cellForRowAt: indexPath)
        } else {
            return configureAddressCell(tableView, cellForRowAt: indexPath)
        }
    }

    func configureNoMatchCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WebAddressWizardContent.noMatchCellReuseIdentifier) ?? {
            // Create and configure a new TableView cell if one hasn't been queued yet
            let newCell = UITableViewCell(style: .subtitle, reuseIdentifier: WebAddressWizardContent.noMatchCellReuseIdentifier)
            newCell.detailTextLabel?.text = Strings.noMatch
            newCell.detailTextLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
            newCell.detailTextLabel?.textColor = .textSubtle
            newCell.addBottomBorder(withColor: .divider)
            return newCell
        }()

        cell.textLabel?.attributedText = AddressTableViewCell.processName("\(lastSearchQuery ?? "").wordpress.com")
        return cell
    }

    func configureAddressCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddressTableViewCell.self)) as? AddressTableViewCell else {
            assertionFailure("This is a programming error - AddressCell has not been properly registered!")
            return UITableViewCell()
        }

        let domainSuggestion = data[indexPath.row]
        if domainPurchasingEnabled {
            let tags = AddressTableViewCell.ViewModel.tagsFromPosition(indexPath.row)
            let viewModel = AddressTableViewCell.ViewModel(model: domainSuggestion, tags: tags)
            cell.update(with: viewModel)
        } else {
            cell.update(with: domainSuggestion)
            cell.addBorder(isFirstCell: (indexPath.row == 0), isLastCell: (indexPath.row == data.count - 1))
            cell.isSelected = domainSuggestion.domainName == selectedDomain?.domainName
        }

        return cell
    }

    func configureErrorCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier()) as? InlineErrorRetryTableViewCell else {
            assertionFailure("This is a programming error - InlineErrorRetryTableViewCell has not been properly registered!")
            return UITableViewCell()
        }

        cell.setMessage(errorMessage)
        return cell
    }
}

// MARK: UITableViewDelegate
extension DomainSelectionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Prevent selection if it's the no matches cell
        return (!domainPurchasingEnabled && !hasExactMatch && indexPath.section == 0) ? nil : indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isShowingError else {
            retry()
            return
        }

        let domainSuggestion = data[indexPath.row]
        self.selectedDomain = domainSuggestion

        if domainPurchasingEnabled {
            searchBar.resignFirstResponder()
        } else {
            searchTextField.resignFirstResponder()
        }
    }

    func retry() {
        let retryQuery = lastSearchQuery ?? ""
        performSearchIfNeeded(query: retryQuery)
    }
}

// MARK: - Transfer Footer Setup

private extension DomainSelectionViewController {
    func setupTransferFooterView() {
        guard domainSelectionType == .purchaseFromDomainManagement else {
            return
        }
        self.view.addSubview(transferFooterView)
        self.transferFooterView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(transferFooterViewConstraints.visible)
    }

    /// Updates transfer footer view constraints to either hide or show the view.
    private func updateTransferFooterViewConstraints(hidden: Bool, animated: Bool = true) {
        guard transferFooterView.superview != nil else {
            return
        }

        let constraints = transferFooterViewConstraints
        let duration = animated ? WPAnimationDurationDefault : 0

        NSLayoutConstraint.deactivate(hidden ? constraints.visible : constraints.hidden)
        NSLayoutConstraint.activate(hidden ? constraints.hidden : constraints.visible)

        if !hidden {
            self.transferFooterView.isHidden = false
        }
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.transferFooterView.isHidden = hidden
            self.view.setNeedsLayout()
        }
    }

    private func showTransferFooterView(animated: Bool = true) {
        self.updateTransferFooterViewConstraints(hidden: false, animated: animated)
    }

    private func hideTransferFooterView(animated: Bool = true) {
        self.updateTransferFooterViewConstraints(hidden: true, animated: animated)
    }
}
