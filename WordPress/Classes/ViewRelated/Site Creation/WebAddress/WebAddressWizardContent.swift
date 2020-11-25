import UIKit
import WordPressAuthenticator

/// Contains the UI corresponding to the list of Domain suggestions.
///
final class WebAddressWizardContent: CollapsableHeaderViewController {

    // MARK: Properties
    private struct Metrics {
        static let maxLabelWidth        = CGFloat(290)
        static let noResultsTopInset    = CGFloat(64)
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

    /// The underlying data represented by the provider
    var data: [DomainSuggestion] {
        didSet {
            contentSizeWillChange()
            table.reloadData()
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

    override func estimatedContentSize() -> CGSize {
        guard !isShowingError else { return CGSize(width: view.frame.width, height: 44) }
        guard data.count > 0 else { return .zero }
        let estimatedSectionHeaderHeight: CGFloat = 85
        let height = estimatedSectionHeaderHeight + (CGFloat(data.count) * AddressCell.estimatedSize.height)
        return CGSize(width: view.frame.width, height: height)
    }

    // MARK: Private behavior
    private func clearContent() {
        throttle.cancel()
        itemSelectionChanged(false)
        data = []
    }

    private func fetchAddresses(_ searchTerm: String) {
        isShowingError = false
        // If the segment ID isn't set (which could happen in the case of the user skipping the site design selection) we'll fall through and search for dotcom only domains.
        guard let segmentID = siteCreator.segment?.identifier ?? siteCreator.design?.segmentID else {
            fetchDotComAddresses(searchTerm)
            return
        }

        updateIcon(isLoading: true)
        service.addresses(for: searchTerm, segmentID: segmentID) { [weak self] results in
            DispatchQueue.main.async {
                self?.handleResult(results)
            }
        }
    }

    // Fetches Addresss suggestions for dotCom sites without requiring a segment.
    private func fetchDotComAddresses(_ searchTerm: String) {
        guard FeatureFlag.siteCreationHomePagePicker.enabled else { return }

        updateIcon(isLoading: true)
        service.addresses(for: searchTerm) { [weak self] results in
            DispatchQueue.main.async {
                self?.handleResult(results)
            }
        }
    }

    private func handleResult(_ results: Result<[DomainSuggestion], Error>) {
        updateIcon(isLoading: false)
        switch results {
        case .failure(let error):
            handleError(error)
        case .success(let data):
            handleData(data)
        }
    }

    private func handleData(_ data: [DomainSuggestion]) {
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
            return
        }

        lastSearchQuery = query

        guard isNetworkActive == true else {
            isShowingError = true
            return
        }

        throttle.throttle { [weak self] in
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
        static let searchPlaceholder: String = NSLocalizedString("Search Domains",
                                                                 comment: "Site creation. Seelect a domain, search field placeholder")
        static let searchAccessibility: String = NSLocalizedString("Searches for available domains to use for your site.",
                                                                   comment: "Accessibility hint for the domains search field in Site Creation.")
        static let suggestions: String = NSLocalizedString("Suggestions",
                                                           comment: "Suggested domains")
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
        return data.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard data.count > 0 else { return nil }
        return Strings.suggestions
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowingError {
            return configureErrorCell(tableView, cellForRowAt: indexPath)
        } else {
            return configureAddressCell(tableView, cellForRowAt: indexPath)
        }
    }

    func configureAddressCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.cellReuseIdentifier()) as? AddressCell else {
            assertionFailure("This is a programming error - AddressCell has not been properly registered!")
            return UITableViewCell()
        }

        let domainSuggestion = data[indexPath.row]
        cell.model = domainSuggestion
        cell.isSelected = domainSuggestion.domainName == selectedDomain?.domainName

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
