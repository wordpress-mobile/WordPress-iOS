import UIKit
import WordPressAuthenticator

/// Contains the UI corresponding to the list of Domain suggestions.
///
final class WebAddressWizardContent: UIViewController {

    // MARK: Properties

    private struct Metrics {
        static let maxLabelWidth        = CGFloat(290)
        static let noResultsTopInset    = CGFloat(64)
    }

    /// The creator collects user input as they advance through the wizard flow.
    private let siteCreator: SiteCreator

    private let service: SiteAddressService

    private let selection: (DomainSuggestion) -> Void

    /// Tracks the site address selected by users
    private var selectedDomain: DomainSuggestion?

    /// The table view renders our server content
    @IBOutlet private weak var table: UITableView!

    /// The view wrapping the skip button
    @IBOutlet private weak var buttonWrapper: ShadowView!

    /// The Create Site button
    @IBOutlet private weak var createSite: NUXButton!

    /// The constraint between the bottom of the buttonWrapper and this view controller's view
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!

    /// Serves as both the data source & delegate of the table view
    private(set) var tableViewProvider: TableViewProvider?

    /// Manages header visibility, keyboard management, and table view offset
    private(set) var tableViewOffsetCoordinator: TableViewOffsetCoordinator?

    /// The throttle meters requests to the remote service
    private let throttle = Scheduler(seconds: 0.5)

    /// We track the last searched value so that we can retry
    private var lastSearchQuery: String? = nil

    /// Locally tracks the network connection status via `NetworkStatusDelegate`
    private var isNetworkActive = ReachabilityUtils.isInternetReachable()

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("Choose a domain name for your site",
                                      comment: "Create site, step 4. Select domain name. Title")

        let subtitle = NSLocalizedString("This is where people will find you on the internet",
                                         comment: "Create site, step 4. Select domain name. Subtitle")

        return SiteCreationHeaderData(title: title, subtitle: subtitle)
    }()

    /// This message advises the user that
    private let noResultsLabel: UILabel

    private let isBottomToolbarAlwaysVisible = UIAccessibility.isVoiceOverRunning

    // MARK: WebAddressWizardContent

    init(creator: SiteCreator, service: SiteAddressService, selection: @escaping (DomainSuggestion) -> Void) {
        self.siteCreator = creator
        self.service = service
        self.selection = selection

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

        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableViewOffsetCoordinator = TableViewOffsetCoordinator(coordinated: table, footerControlContainer: view, footerControl: buttonWrapper, toolbarBottomConstraint: bottomConstraint)

        toggleBottomToolbar(enabled: false)

        applyTitle()
        setupBackground()
        setupButtonWrapper()
        setupCreateSiteButton()
        setupTable()
        WPAnalytics.track(.enhancedSiteCreationDomainsAccessed)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeNetworkStatus()
        tableViewOffsetCoordinator?.startListeningToKeyboardNotifications()
        prepareViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignTextFieldResponderIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restoreSearchIfNeeded()
        postScreenChangedForVoiceOver()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        tableViewOffsetCoordinator?.stopListeningToKeyboardNotifications()
        clearContent()
    }

    private func textFieldResignFirstResponder() {
        guard let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return
        }

        header.textField.resignFirstResponder()
    }

    // MARK: Private behavior

    private func applyTitle() {
        title = NSLocalizedString("2 of 2", comment: "Site creation. Step 2. Screen title")
    }

    private func clearContent() {
        throttle.cancel()

        toggleBottomToolbar(enabled: false)

        guard let validDataProvider = tableViewProvider as? WebAddressTableViewProvider else {
            setupTableDataProvider(isShowingImplicitSuggestions: true)
            return
        }

        validDataProvider.data = []
        validDataProvider.isShowingImplicitSuggestions = true
        tableViewOffsetCoordinator?.resetTableOffsetIfNeeded()
    }

    private func fetchAddresses(_ searchTerm: String) {
        // It's not ideal to let the segment ID be optional at this point, but in order to avoid overcomplicating my current
        // task, I'll default to silencing this situation.  Since the segment ID should exist, this silencing should not
        // really be triggered for now.
        guard let segmentID = siteCreator.segment?.identifier else {
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

    private func handleData(_ data: [DomainSuggestion]) {
        let header = self.table.tableHeaderView as! TitleSubtitleTextfieldHeader
        let isShowingImplicitSuggestions = header.textField.text!.isEmpty

        if let validDataProvider = tableViewProvider as? WebAddressTableViewProvider {
            validDataProvider.data = data
            validDataProvider.isShowingImplicitSuggestions = isShowingImplicitSuggestions
        } else {
            setupTableDataProvider(data, isShowingImplicitSuggestions: isShowingImplicitSuggestions)
        }

        if data.isEmpty {
            noResultsLabel.isHidden = false
        } else {
            noResultsLabel.isHidden = true
        }

        if !isShowingImplicitSuggestions {
            postSuggestionsUpdateAnnouncementForVoiceOver(listIsEmpty: data.isEmpty)
        }
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
            self?.fetchAddresses(query)
        }
    }

    private func setupBackground() {
        view.backgroundColor = .listBackground
    }

    private func setupButtonWrapper() {
        buttonWrapper.backgroundColor = .listBackground
    }

    private func setupCreateSiteButton() {
        createSite.addTarget(self, action: #selector(commitSelection), for: .touchUpInside)

        let buttonTitle = NSLocalizedString("Create Site", comment: "Button to progress to the next step")
        createSite.setTitle(buttonTitle, for: .normal)
        createSite.accessibilityLabel = buttonTitle
        createSite.accessibilityHint = NSLocalizedString("Creates a new site with the given information.",
                                                         comment: "Accessibility hint for the Create Site button in Site Creation.")

        createSite.isPrimary = true
    }

    @objc
    private func commitSelection() {
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

    private func resignTextFieldResponderIfNeeded() {
        guard let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return
        }

        let textField = header.textField
        textField.resignFirstResponder()
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

        tableViewProvider = InlineErrorTableViewProvider(tableView: table, message: message, selectionHandler: handler)
    }

    private func setupHeaderAndNoResultsMessage() {
        let header = TitleSubtitleTextfieldHeader(frame: .zero)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

        header.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        header.textField.delegate = self

        header.accessibilityTraits = .header

        let placeholderText = NSLocalizedString("Search Domains", comment: "Site creation. Seelect a domain, search field placeholder")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(.textPlaceholder)
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        header.textField.attributedPlaceholder = attributedPlaceholder

        header.textField.accessibilityHint = NSLocalizedString("Searches for available domains to use for your site.", comment: "Accessibility hint for the domains search field in Site Creation.")

        table.tableHeaderView = header

        view.addSubview(noResultsLabel)

        NSLayoutConstraint.activate([
            header.centerXAnchor.constraint(equalTo: table.centerXAnchor),
            header.widthAnchor.constraint(equalTo: table.widthAnchor),
            header.topAnchor.constraint(equalTo: table.topAnchor),
            noResultsLabel.widthAnchor.constraint(equalTo: header.textField.widthAnchor),
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.topAnchor.constraint(equalTo: header.textField.bottomAnchor, constant: Metrics.noResultsTopInset)
        ])

        table.tableHeaderView?.layoutIfNeeded()
        table.tableHeaderView = table.tableHeaderView
    }

    private func setupTable() {
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupConstraints()
        setupHeaderAndNoResultsMessage()
        hideSeparators()
    }

    private func setupTableBackground() {
        table.backgroundColor = .listBackground
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

    private func setupTableDataProvider(_ data: [DomainSuggestion] = [], isShowingImplicitSuggestions: Bool) {
        let handler: CellSelectionHandler = { [weak self] selectedIndexPath in
            guard let self = self, let provider = self.tableViewProvider as? WebAddressTableViewProvider else {
                return
            }

            let domainSuggestion = provider.data[selectedIndexPath.row]
            self.selectedDomain = domainSuggestion
            self.resignTextFieldResponderIfNeeded()
            self.toggleBottomToolbar(enabled: true)
        }

        let provider = WebAddressTableViewProvider(tableView: table, data: data, selectionHandler: handler)
        provider.isShowingImplicitSuggestions = isShowingImplicitSuggestions

        self.tableViewProvider = provider
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
        toggleBottomToolbar(enabled: false)
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
        tableViewOffsetCoordinator?.adjustTableOffsetIfNeeded()
    }

    // MARK: - Toolbar

    private func toggleBottomToolbar(enabled: Bool) {
        createSite.isEnabled = enabled

        if enabled {
            tableViewOffsetCoordinator?.showBottomToolbar()
        } else {
            if !isBottomToolbarAlwaysVisible {
                tableViewOffsetCoordinator?.hideBottomToolbar()
            }
        }
    }

    // MARK: - Others

    private enum Strings {
        static let suggestionsUpdated = NSLocalizedString("Suggestions updated",
                                                          comment: "Announced by VoiceOver when new domains suggestions are shown in Site Creation.")
        static let noResults = NSLocalizedString("No available addresses matching your search",
                                                 comment: "Advises the user that no Domain suggestions could be found for the search query.")
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
        tableViewOffsetCoordinator?.resetTableOffsetIfNeeded()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        clearSelectionAndCreateSiteButton()
        return true
    }
}

extension WebAddressWizardContent {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    func preferredContentSizeDidChange() {
        tableViewOffsetCoordinator?.adjustTableOffsetIfNeeded()
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
