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
    private let searchHeader: SearchTextField

    /// The underlying data represented by the provider
    var data: [DomainSuggestion] {
        didSet {
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

    private let isBottomToolbarAlwaysVisible = UIAccessibility.isVoiceOverRunning

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
        self.searchHeader = SearchTextField()
        table = UITableView(frame: .zero, style: .grouped)
        super.init(scrollableView: table,
                   mainTitle: NSLocalizedString("Choose a domain", comment: "Select domain name. Title"),
                   prompt: NSLocalizedString("This is where people will find you on the internet", comment: "Select domain name. Subtitle"),
                   primaryActionTitle: NSLocalizedString("Create Site", comment: "Button to progress to the next step"),
                   accessoryView: searchHeader)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupTable()
        WPAnalytics.track(.enhancedSiteCreationDomainsAccessed)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeNetworkStatus()
        prepareViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchHeader.resignFirstResponder()
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

    private func textFieldResignFirstResponder() {
        guard let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return
        }

        header.textField.resignFirstResponder()
    }

    // MARK: Private behavior
    private func clearContent() {
        throttle.cancel()
        itemSelectionChanged(false)
        data = []
    }

    private func fetchAddresses(_ searchTerm: String) {
        // If the segment ID isn't set (which could happen in the case of the user skipping the site design selection) we'll fall through and search for dotcom only domains.
        guard let segmentID = siteCreator.segment?.identifier ?? siteCreator.design?.segmentID else {
            fetchDotComAddresses(searchTerm)
            return
        }

        updateIcon(isLoading: true)
        service.addresses(for: searchTerm, segmentID: segmentID) { [weak self] results in
            self?.updateIcon(isLoading: false)
            switch results {
            case .failure(let error):
                self?.handleError(error)
            case .success(let data):
                self?.handleData(data)
            }
        }
    }

    // Fetches Addresss suggestions for dotCom sites without requiring a segment.
    private func fetchDotComAddresses(_ searchTerm: String) {
        guard FeatureFlag.siteCreationHomePagePicker.enabled else { return }

        updateIcon(isLoading: true)
        service.addresses(for: searchTerm) { [weak self] results in
            self?.updateIcon(isLoading: false)
            switch results {
            case .failure(let error):
                self?.handleError(error)
            case .success(let data):
                self?.handleData(data)
            }
        }
    }

    private func handleData(_ data: [DomainSuggestion]) {
        self.data = data
        if data.isEmpty {
            noResultsLabel.isHidden = false
        } else {
            noResultsLabel.isHidden = true
        }
        postSuggestionsUpdateAnnouncementForVoiceOver(listIsEmpty: data.isEmpty)
    }

    private func handleError(_ error: Error) {
        setupEmptyTableProvider()
    }

    private func hideSeparators() {
        table.tableFooterView = UIView(frame: .zero)
    }

    private func performSearchIfNeeded(query: String) {
        guard !query.isEmpty else {
            return
        }

        lastSearchQuery = query

        guard isNetworkActive == true else {
            setupEmptyTableProvider()
            return
        }

        throttle.throttle { [weak self] in
            guard let self = self else { return }
            self.fetchAddresses(query)
        }
    }

    private func setupBackground() {
        view.backgroundColor = .listBackground
    }

    override func primaryActionSelected(_ sender: Any) {
        guard let selectedDomain = selectedDomain else {
            return
        }

        selection(selectedDomain)
        trackDomainsSelection(selectedDomain)
    }

    private func setupCells() {
        let cellName = AddressCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        table.register(nib, forCellReuseIdentifier: cellName)

        table.register(InlineErrorRetryTableViewCell.self, forCellReuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
    }

    private func restoreSearchIfNeeded() {
        guard let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return
        }

        search(withInputFrom: header.textField)
    }

    private func prepareViewIfNeeded() {
        guard let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return
        }

        let textField = header.textField
        textField.becomeFirstResponder()
    }

    private func setupEmptyTableProvider() {
        let message: InlineErrorMessage
        if isNetworkActive {
            message = InlineErrorMessages.serverError
        } else {
            message = InlineErrorMessages.noConnection
        }

        let handler: CellSelectionHandler = { [weak self] _ in
            let retryQuery = self?.lastSearchQuery ?? ""
            self?.performSearchIfNeeded(query: retryQuery)
        }

//        tableViewProvider = InlineErrorTableViewProvider(tableView: table, message: message, selectionHandler: handler)
    }

    private func setupHeaderAndNoResultsMessage() {
        searchHeader.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchHeader.delegate = self
        searchHeader.accessibilityTraits = .searchField

        let placeholderText = NSLocalizedString("Search Domains", comment: "Site creation. Seelect a domain, search field placeholder")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(.textPlaceholder)
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        searchHeader.attributedPlaceholder = attributedPlaceholder

        searchHeader.accessibilityHint = NSLocalizedString("Searches for available domains to use for your site.", comment: "Accessibility hint for the domains search field in Site Creation.")

        view.addSubview(noResultsLabel)

        NSLayoutConstraint.activate([
            noResultsLabel.widthAnchor.constraint(equalTo: headerView.widthAnchor),
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: Metrics.noResultsTopInset)
        ])
    }

    private func setupTable() {
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupConstraints()
        setupHeaderAndNoResultsMessage()
        hideSeparators()
        table.delegate = self
        table.dataSource = self
        table.reloadData()
    }

    private func setupTableBackground() {
        table.backgroundColor = .basicBackground
    }

    private func setupTableSeparator() {
        table.separatorColor = .divider
    }

    private func setupConstraints() {
        table.cellLayoutMarginsFollowReadableWidth = true

        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.prevailingLayoutGuide.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.prevailingLayoutGuide.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.prevailingLayoutGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.prevailingLayoutGuide.trailingAnchor),
        ])
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
        guard let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return
        }
        header.textField.setIcon(isLoading: isLoading)
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
    }

    private func addBorder(cell: UITableViewCell, at: IndexPath) {
        let row = at.row
        if row == 0 {
            cell.addTopBorder(withColor: .neutral(.shade10))
        }

        if row == data.count - 1 {
            cell.addBottomBorder(withColor: .neutral(.shade10))
        }
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
        return data.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard data.count > 0 else {
            return nil
        }

        return NSLocalizedString("Suggestions", comment: "Suggested domains")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.cellReuseIdentifier()) as? AddressCell else {
            assertionFailure("This is a programming error - AddressCell has not been properly registered!")
            return UITableViewCell()
        }

        let domainSuggestion = data[indexPath.row]
        cell.model = domainSuggestion

        addBorder(cell: cell, at: indexPath)

        return cell
    }
}

// MARK: UITableViewDelegate
extension WebAddressWizardContent: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let domainSuggestion = data[indexPath.row]
        self.selectedDomain = domainSuggestion
        searchHeader.resignFirstResponder()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1.0))
    }
}
