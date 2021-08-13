import UIKit
import WordPressAuthenticator

/// Contains the UI corresponding to the list of Domain suggestions.
///
final class WebAddressWizardContent: CollapsableHeaderViewController {
    static let noMatchCellReuseIdentifier = "noMatchCellReuseIdentifier"

    // MARK: Properties
    private struct Metrics {
        static let maxLabelWidth            = CGFloat(290)
        static let noResultsTopInset        = CGFloat(64)
        static let sitePromptEdgeMargin     = CGFloat(50)
        static let sitePromptBottomMargin   = CGFloat(10)
        static let sitePromptTopMargin      = CGFloat(25)
    }

    override var seperatorStyle: SeperatorStyle {
        return .hidden
    }

    /// The creator collects user input as they advance through the wizard flow.
    private let siteCreator: SiteCreator
    private let service: SiteAddressService
    private let selection: (DomainSuggestion) -> Void

    /// Tracks the site address selected by users
    private var selectedDomain: DomainSuggestion? {
        didSet {
            itemSelectionChanged(selectedDomain != nil)
        }
    }

    /// The table view renders our server content
    private let table: UITableView
    private let searchHeader: UIView
    private let searchTextField: SearchTextField
    private var sitePromptView: SitePromptView!

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

    /// This message advises the user that
    private let noResultsLabel: UILabel
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

    // MARK: WebAddressWizardContent

    init(creator: SiteCreator, service: SiteAddressService, selection: @escaping (DomainSuggestion) -> Void) {
        self.siteCreator = creator
        self.service = service
        self.selection = selection
        self.data = []
        self.noResultsLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.preferredMaxLayoutWidth = Metrics.maxLabelWidth

            label.font = WPStyleGuide.fontForTextStyle(.title2)
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
                   primaryActionTitle: Strings.createSite,
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
    }

    private func loadHeaderView() {
        let top = NSLayoutConstraint(item: searchTextField, attribute: .top, relatedBy: .equal, toItem: searchHeader, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: searchTextField, attribute: .bottom, relatedBy: .equal, toItem: searchHeader, attribute: .bottom, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: searchTextField, attribute: .leading, relatedBy: .equal, toItem: searchHeader, attribute: .leadingMargin, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: searchTextField, attribute: .trailing, relatedBy: .equal, toItem: searchHeader, attribute: .trailingMargin, multiplier: 1, constant: 0)
        searchHeader.addSubview(searchTextField)
        searchHeader.addConstraints([top, bottom, leading, trailing])
        searchHeader.addTopBorder(withColor: .divider)
        searchHeader.addBottomBorder(withColor: .divider)
        searchHeader.backgroundColor = searchTextField.backgroundColor
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

        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let `self` = self else { return }
            if !self.sitePromptView.isHidden {
                self.updateTitleViewVisibility(true)
            }
        }
    }

    override func estimatedContentSize() -> CGSize {
        guard !isShowingError else { return CGSize(width: view.frame.width, height: 44) }
        guard data.count > 0 else { return .zero }
        let estimatedSectionHeaderHeight: CGFloat = 85
        let cellCount = hasExactMatch ? data.count : data.count + 1
        let height = estimatedSectionHeaderHeight + (CGFloat(cellCount) * AddressCell.estimatedSize.height)
        return CGSize(width: view.frame.width, height: height)
    }

    // MARK: Private behavior
    private func clearContent() {
        throttle.cancel()
        itemSelectionChanged(false)
        data = []
        lastSearchQuery = nil
        setAddressHintVisibility(isHidden: false)
        expandHeader()
    }

    private func fetchAddresses(_ searchTerm: String) {
        isShowingError = false
        updateIcon(isLoading: true)
        service.addresses(for: searchTerm) { [weak self] results in
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
            handleData(data.domainSuggestions)
        }
    }

    private func handleData(_ data: [DomainSuggestion]) {
        setAddressHintVisibility(isHidden: true)
        let resultsHavePreviousSelection = data.contains { (suggestion) -> Bool in self.selectedDomain?.domainName == suggestion.domainName }
        if !resultsHavePreviousSelection {
            clearSelectionAndCreateSiteButton()
        }

        self.data = data
        if data.isEmpty {
            noResultsLabel.isHidden = false
        } else {
            noResultsLabel.isHidden = true
        }
        postSuggestionsUpdateAnnouncementForVoiceOver(listIsEmpty: data.isEmpty)
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
        let cellName = AddressCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        table.register(nib, forCellReuseIdentifier: cellName)
        table.register(InlineErrorRetryTableViewCell.self, forCellReuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
        table.cellLayoutMarginsFollowReadableWidth = true
    }

    private func restoreSearchIfNeeded() {
        search(withInputFrom: searchTextField)
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

        NSLayoutConstraint.activate([
            noResultsLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor),
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: Metrics.noResultsTopInset)
        ])
    }

    private func setupTable() {
        table.dataSource = self
        table.estimatedRowHeight = AddressCell.estimatedSize.height
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupHeaderAndNoResultsMessage()
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .none // Remove Seperator from from section headers we'll add in seperators when creating cells.
    }

    private func setupTableBackground() {
        table.backgroundColor = .basicBackground
    }

    private func setupTableSeparator() {
        table.separatorColor = .divider
    }

    private func query(from textField: UITextField?) -> String? {
        guard let text = textField?.text,
            !text.isEmpty else {
                return siteCreator.information?.title
        }

        return text
    }

    @objc
    private func textChanged(sender: UITextField) {
        search(withInputFrom: sender)
    }

    private func clearSelectionAndCreateSiteButton() {
        selectedDomain = nil
        table.deselectSelectedRowWithAnimation(true)
        itemSelectionChanged(false)
    }

    private func trackDomainsSelection(_ domainSuggestion: DomainSuggestion) {
        let domainSuggestionProperties: [String: AnyObject] = [
            "chosen_domain": domainSuggestion.domainName as AnyObject,
            "search_term": lastSearchQuery as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationDomainsSelected, withProperties: domainSuggestionProperties)
    }

    // MARK: - Search logic

    func updateIcon(isLoading: Bool) {
        searchTextField.setIcon(isLoading: isLoading)
    }

    private func search(withInputFrom textField: UITextField) {
        guard let query = query(from: textField), query.isEmpty == false else {
            clearContent()
            return
        }

        performSearchIfNeeded(query: query)
    }

    // MARK: - Search logic

    private func setAddressHintVisibility(isHidden: Bool) {
        sitePromptView.isHidden = isHidden
    }

    private func addAddressHintView() {
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
        setAddressHintVisibility(isHidden: true)
    }

    // MARK: - Others

    private enum Strings {
        static let suggestionsUpdated = NSLocalizedString("Suggestions updated",
                                                          comment: "Announced by VoiceOver when new domains suggestions are shown in Site Creation.")
        static let noResults = NSLocalizedString("No available addresses matching your search",
                                                 comment: "Advises the user that no Domain suggestions could be found for the search query.")
        static let noConnection: String = NSLocalizedString("No connection",
                                                            comment: "Displayed during Site Creation, when searching for Verticals and the network is unavailable.")
        static let serverError: String = NSLocalizedString("There was a problem",
                                                           comment: "Displayed during Site Creation, when searching for Verticals and the server returns an error.")
        static let mainTitle: String = NSLocalizedString("Choose a domain",
                                                         comment: "Select domain name. Title")
        static let prompt: String = NSLocalizedString("This is where people will find you on the internet.",
                                                      comment: "Select domain name. Subtitle")
        static let createSite: String = NSLocalizedString("Create Site",
                                                          comment: "Button to progress to the next step")
        static let searchPlaceholder: String = NSLocalizedString("Type a name for your site",
                                                                 comment: "Site creation. Seelect a domain, search field placeholder")
        static let searchAccessibility: String = NSLocalizedString("Searches for available domains to use for your site.",
                                                                   comment: "Accessibility hint for the domains search field in Site Creation.")
        static let suggestions: String = NSLocalizedString("Suggestions",
                                                           comment: "Suggested domains")
        static let noMatch: String = NSLocalizedString("This domain is unavailable",
                                                           comment: "Notifies the user that the a domain matching the search term wasn't returned in the results")
    }
}

// MARK: - NetworkStatusDelegate

extension WebAddressWizardContent: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        isNetworkActive = active
    }
}

// MARK: - UITextFieldDelegate

extension WebAddressWizardContent: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        clearSelectionAndCreateSiteButton()
        return true
    }
}

// MARK: - VoiceOver

private extension WebAddressWizardContent {
    func postScreenChangedForVoiceOver() {
        UIAccessibility.post(notification: .screenChanged, argument: table.tableHeaderView)
    }

    func postSuggestionsUpdateAnnouncementForVoiceOver(listIsEmpty: Bool) {
        let message: String = listIsEmpty ? Strings.noResults : Strings.suggestionsUpdated
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// MARK: UITableViewDataSource
extension WebAddressWizardContent: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isShowingError else { return 1 }
        return (!hasExactMatch && section == 0) ? 1 : data.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard data.count > 0 else { return nil }
        return (!hasExactMatch && section == 0) ? nil : Strings.suggestions
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (!hasExactMatch && indexPath.section == 0) ? 60 : UITableView.automaticDimension
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return hasExactMatch ? 1 : 2
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return (!hasExactMatch && section == 0) ? UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 3)) : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowingError {
            return configureErrorCell(tableView, cellForRowAt: indexPath)
        } else if !hasExactMatch && indexPath.section == 0 {
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

        cell.textLabel?.attributedText = AddressCell.processName("\(lastSearchQuery ?? "").wordpress.com")
        return cell
    }

    func configureAddressCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.cellReuseIdentifier()) as? AddressCell else {
            assertionFailure("This is a programming error - AddressCell has not been properly registered!")
            return UITableViewCell()
        }

        let domainSuggestion = data[indexPath.row]
        cell.model = domainSuggestion
        cell.isSelected = domainSuggestion.domainName == selectedDomain?.domainName
        cell.addBorder(isFirstCell: (indexPath.row == 0), isLastCell: (indexPath.row == data.count - 1))
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
extension WebAddressWizardContent: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Prevent selection if it's the no matches cell
        return (!hasExactMatch && indexPath.section == 0) ? nil : indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isShowingError else {
            retry()
            return
        }

        let domainSuggestion = data[indexPath.row]
        self.selectedDomain = domainSuggestion
        searchTextField.resignFirstResponder()
    }

    func retry() {
        let retryQuery = lastSearchQuery ?? ""
        performSearchIfNeeded(query: retryQuery)
    }
}
