import UIKit
import WordPressKit
import WordPressAuthenticator

/// Contains the UI corresponding to the list of verticals
///
final class VerticalsWizardContent: UIViewController {
    // MARK: Properties

    private static let defaultPrompt = SiteVerticalsPrompt(
        title: NSLocalizedString("What's the focus of your business?",
                                 comment: "Create site, step 2. Select focus of the business. Title"),
        subtitle: NSLocalizedString("We'll use your answer to add sections to your website.",
                                    comment: "Create site, step 2. Select focus of the business. Subtitle"),
        hint: NSLocalizedString("e.g. Landscaping, Consulting... etc.",
                                comment: "Site creation. Select focus of your business, search field placeholder")
    )

    /// A collection of parameters uses for view layout
    private struct Metrics {
        static let rowHeight: CGFloat = 44.0
        static let separatorInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 0)
    }

    /// The creator collects user input as they advance through the wizard flow.
    private let siteCreator: SiteCreator

    /// The service which retrieves localized prompt verbiage specific to the chosen segment
    private let promptService: SiteVerticalsPromptService

    /// The service which conducts searches for know verticals
    private let verticalsService: SiteVerticalsService

    /// The action to perform once a Vertical is selected by the user
    private let selection: (SiteVertical?) -> Void

    /// Makes sure we don't call the selection handler twice.
    private var selectionHandled = false

    /// The localized prompt retrieved by remote service; `nil` otherwise
    private var prompt: SiteVerticalsPrompt?

    /// We track the last prompt segment so that we can retry somewhat intelligently
    private var lastSegmentIdentifer: Int64? = nil

    /// The throttle meters requests to the remote verticals service
    private let throttle = Scheduler(seconds: 0.5)

    /// We track the last searched value so that we can retry
    private var lastSearchQuery: String? = nil

    /// Locally tracks the network connection status via `NetworkStatusDelegate`
    private var isNetworkActive = ReachabilityUtils.isInternetReachable()

    /// The table view renders our server content
    @IBOutlet private weak var table: UITableView!

    /// The view wrapping the skip button
    @IBOutlet weak var buttonWrapper: ShadowView!

    /// The skip button
    @IBOutlet weak var nextStep: NUXButton!

    /// The constraint between the bottom of the buttonWrapper and this view controller's view
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    /// Serves as both the data source & delegate of the table view
    private(set) var tableViewProvider: TableViewProvider?

    /// Manages header visibility, keyboard management, and table view offset
    private(set) var tableViewOffsetCoordinator: TableViewOffsetCoordinator?

    // MARK: VerticalsWizardContent

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - creator:            accumulates user input as a user navigates through the site creation flow
    ///   - promptService:      the service which retrieves localized prompt verbiage specific to the chosen segment
    ///   - verticalsService:   the service which conducts searches for know verticals
    ///   - selection:          the action to perform once a Vertical is selected by the user
    ///
    init(creator: SiteCreator, promptService: SiteVerticalsPromptService, verticalsService: SiteVerticalsService, selection: @escaping (SiteVertical?) -> Void) {
        self.siteCreator = creator
        self.promptService = promptService
        self.verticalsService = verticalsService
        self.selection = selection

        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restoreSearchIfNeeded()
        selectionHandled = false
        postScreenChangedForVoiceOver()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableViewOffsetCoordinator?.stopListeningToKeyboardNotifications()
        clearContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        table.layoutHeaderView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableViewOffsetCoordinator = TableViewOffsetCoordinator(coordinated: table, footerControlContainer: view, footerControl: buttonWrapper, toolbarBottomConstraint: bottomConstraint)

        applyTitle()
        setupBackground()
        setupButtonWrapper()
        setupNextButton()
        setupTable()
        WPAnalytics.track(.enhancedSiteCreationVerticalsViewed)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchPromptIfNeeded()
        observeNetworkStatus()
        tableViewOffsetCoordinator?.startListeningToKeyboardNotifications()
        prepareViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignTextFieldResponderIfNeeded()
    }

    // MARK: Private behavior

    private func applyTitle() {
        title = NSLocalizedString("1 of 3", comment: "Site creation. Step 2. Screen title")
    }

    private func clearContent() {
        throttle.cancel()

        guard let validDataProvider = tableViewProvider as? VerticalsTableViewProvider else {
            setupTableDataProvider()
            return
        }
        validDataProvider.data = []
        tableViewOffsetCoordinator?.resetTableOffsetIfNeeded()
        tableViewOffsetCoordinator?.showBottomToolbar()
    }

    private func fetchPromptIfNeeded() {
        // This should never apply, but we have a Segment?
        guard let promptRequest = siteCreator.segment?.identifier else {
            let defaultPrompt = VerticalsWizardContent.defaultPrompt
            setupTableHeaderWithPrompt(defaultPrompt)

            return
        }

        // We have already obtained this prompt
        if prompt != nil, let lastRequestPromptIdentifier = lastSegmentIdentifer, lastRequestPromptIdentifier == promptRequest {
            return
        }

        // We are essentially resetting our search for a new segment ID
        table.tableHeaderView = nil
        prompt = nil
        lastSearchQuery = nil
        lastSegmentIdentifer = promptRequest

        promptService.retrieveVerticalsPrompt(request: promptRequest) { [weak self] serverPrompt in
            guard let self = self else {
                return
            }

            let prompt: SiteVerticalsPrompt
            if let serverPrompt = serverPrompt {
                prompt = serverPrompt
            } else {
                prompt = VerticalsWizardContent.defaultPrompt
            }

            self.setupTableHeaderWithPrompt(prompt)
        }
    }

    private func fetchVerticals(_ searchTerm: String) {
        let request = SiteVerticalsRequest(search: searchTerm)
        verticalsService.retrieveVerticals(request: request) { [weak self] result in
            switch result {
            case .success(let data):
                self?.handleData(data)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }

    private func handleData(_ data: [SiteVertical]) {
        if let validDataProvider = tableViewProvider as? VerticalsTableViewProvider {
            validDataProvider.data = data
        } else {
            setupTableDataProvider(data)
        }
    }

    private func handleError(_ error: Error? = nil) {
        setupEmptyTableProvider()
    }

    private func hideSeparators() {
        table.tableFooterView = UIView(frame: .zero)
    }

    private func performSearchIfNeeded(query: String) {
        guard !query.isEmpty else {
            return
        }

        tableViewOffsetCoordinator?.hideBottomToolbar()

        lastSearchQuery = query

        guard isNetworkActive == true else {
            setupEmptyTableProvider()
            return
        }

        throttle.throttle { [weak self] in
            self?.fetchVerticals(query)
        }
    }

    private func registerCell(identifier: String) {
        let nib = UINib(nibName: identifier, bundle: nil)
        table.register(nib, forCellReuseIdentifier: identifier)
    }

    private func registerCells() {
        registerCell(identifier: VerticalsCell.cellReuseIdentifier())
        registerCell(identifier: NewVerticalCell.cellReuseIdentifier())

        table.register(InlineErrorRetryTableViewCell.self, forCellReuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
    }

    private func resignTextFieldResponderIfNeeded() {
        guard WPDeviceIdentification.isiPhone(), let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return
        }

        let textField = header.textField
        textField.resignFirstResponder()
    }

    private func restoreSearchIfNeeded() {
        guard let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader, let currentSegmentID = siteCreator.segment?.identifier, let lastSegmentID = lastSegmentIdentifer, currentSegmentID == lastSegmentID else {

            return
        }

        let textField = header.textField
        guard let inputText = textField.text, !inputText.isEmpty else {
            return
        }

        tableViewOffsetCoordinator?.adjustTableOffsetIfNeeded()
        performSearchIfNeeded(query: inputText)
    }

    private func prepareViewIfNeeded() {
        guard WPDeviceIdentification.isiPhone(), let header = self.table.tableHeaderView as? TitleSubtitleTextfieldHeader, let currentSegmentID = siteCreator.segment?.identifier, let lastSegmentID = lastSegmentIdentifer, currentSegmentID == lastSegmentID else {

            return
        }

        let textField = header.textField
        guard let inputText = textField.text, !inputText.isEmpty else {
            return
        }
        textField.becomeFirstResponder()
    }

    private func setupBackground() {
        view.backgroundColor = .listBackground
    }

    private func setupCellHeight() {
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = Metrics.rowHeight
        table.separatorInset = Metrics.separatorInset
    }

    private func setupCells() {
        registerCells()
        setupCellHeight()
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

    private func setupButtonWrapper() {
        buttonWrapper.backgroundColor = .listBackground
    }

    private func setupNextButton() {
        nextStep.addTarget(self, action: #selector(skip), for: .touchUpInside)

        setupButtonAsSkip()
    }

    private func setupButtonAsSkip() {
        let buttonTitle = NSLocalizedString("Skip", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step without making changes", comment: "Site creation. Navigates to the next step")

        nextStep.isPrimary = false
    }

    private func setupTable() {
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupConstraints()
        hideSeparators()

        setupTableDataProvider()
    }

    private func setupTableBackground() {
        table.backgroundColor = .listBackground
    }

    private func setupTableHeaderWithPrompt(_ prompt: SiteVerticalsPrompt) {
        self.prompt = prompt

        table.tableHeaderView = nil

        let header = TitleSubtitleTextfieldHeader(frame: .zero)
        header.setTitle(prompt.title)
        header.setSubtitle(prompt.subtitle)

        header.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        header.textField.delegate = self

        header.accessibilityTraits = .header

        let placeholderText = prompt.hint
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(.textPlaceholder)
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        header.textField.attributedPlaceholder = attributedPlaceholder
        header.textField.returnKeyType = .done

        table.tableHeaderView = header

        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: table.widthAnchor),
            header.centerXAnchor.constraint(equalTo: table.centerXAnchor),
        ])
    }

    private func setupTableDataProvider(_ data: [SiteVertical] = []) {
        let handler: CellSelectionHandler = { [weak self] selectedIndexPath in
            guard let self = self, let provider = self.tableViewProvider as? VerticalsTableViewProvider else {
                return
            }

            let vertical = provider.data[selectedIndexPath.row]
            self.select(vertical)
            self.trackVerticalSelection(vertical)
        }

        self.tableViewProvider = VerticalsTableViewProvider(tableView: table, data: data, selectionHandler: handler)
    }

    private func setupTableSeparator() {
        table.separatorColor = .divider
    }

    private func trackVerticalSelection(_ vertical: SiteVertical) {
        let verticalProperties: [String: AnyObject] = [
            "vertical_name": vertical.title as AnyObject,
            "vertical_id": vertical.identifier as AnyObject,
            "vertical_is_user": vertical.isNew as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationVerticalsSelected, withProperties: verticalProperties)
    }

    @objc
    private func textChanged(sender: UITextField) {
        guard let searchTerm = sender.text, searchTerm.isEmpty == false else {
            clearContent()
            return
        }

        performSearchIfNeeded(query: searchTerm)
        tableViewOffsetCoordinator?.adjustTableOffsetIfNeeded()
    }

    @objc
    private func skip() {
        select(nil)
        WPAnalytics.track(.enhancedSiteCreationVerticalsSkipped)
    }

    private func searchAndSelectVertical(_ textField: UITextField) {
        guard let verticalName = textField.text,
            verticalName.count > 0 else {
                return
        }

        verticalsService.retrieveVertical(named: verticalName) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let vertical):
                // If the user has changed the contents of the text field while the request was being executed
                // we'll cancel the operation
                guard verticalName == textField.text else {
                    return
                }

                self.select(vertical)
            case .failure:
                // For now we're purposedly not taking any action here.
                break
            }
        }
    }

    /// Convenience method to make sure we don't execute the selection handler twice.
    /// We should avoid calling the selection handler directly and user this method instead.
    /// This method is also thread safe.
    ///
    private func select(_ vertical: SiteVertical?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                !self.selectionHandled else {
                    return
            }

            self.selectionHandled = true
            self.selection(vertical)
        }
    }
}

// MARK: - NetworkStatusDelegate

extension VerticalsWizardContent: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        isNetworkActive = active
    }
}

// MARK: - UITextFieldDelegate

extension VerticalsWizardContent: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        tableViewOffsetCoordinator?.resetTableOffsetIfNeeded()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchAndSelectVertical(textField)

        return true
    }
}

extension VerticalsWizardContent {
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

private extension VerticalsWizardContent {
    func postScreenChangedForVoiceOver() {
        UIAccessibility.post(notification: .screenChanged, argument: table.tableHeaderView)
    }
}
