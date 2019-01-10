import UIKit
import WordPressKit

/// Contains the UI corresponding to the list of verticals
///
final class VerticalsWizardContent: UIViewController {

    // MARK: Properties

    /// A collection of parameters uses for view layout
    private struct Metrics {
        static let rowHeight: CGFloat = 44.0
        static let separatorInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 0)
    }

    /// The segment selected by the user in a preceding step
    private let segment: SiteSegment?

    /// The service which retrieves localized prompt verbiage specific to the chosen segment
    private let promptService: SiteVerticalsPromptService

    /// The service which conducts searches for know verticals
    private let verticalsService: SiteVerticalsService

    /// The action to perform once a Vertical is selected by the user
    private let selection: (SiteVertical) -> Void

    /// The localized prompt retrieved by remote service; `nil` otherwise
    private var prompt: SiteVerticalsPrompt?

    /// The throttle meters requests to the remote verticals service
    private let throttle = Scheduler(seconds: 0.5)

    /// We track the last searched value so that we can retry
    private var lastSearchQuery: String? = nil

    /// Locally tracks the network connection status via `NetworkStatusDelegate`
    private var isNetworkActive = ReachabilityUtils.isInternetReachable()

    /// The table view renders our server content
    @IBOutlet private weak var table: UITableView!

    /// Serves as both the data source & delegate of the table view
    private(set) var tableViewProvider: TableViewProvider?

    /// We manipulate the bottom constraint in response to the keyboard.
    private lazy var bottomConstraint: NSLayoutConstraint = {
        return self.table.bottomAnchor.constraint(equalTo: self.view.prevailingLayoutGuide.bottomAnchor)
    }()

    // MARK: VerticalsWizardContent

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - segment:            the segment selected by the user in a preceding step
    ///   - promptService:      the service which retrieves localized prompt verbiage specific to the chosen segment
    ///   - verticalsService:   the service which conducts searches for know verticals
    ///   - selection:          the action to perform once a Vertical is selected by the user
    ///
    init(segment: SiteSegment?, promptService: SiteVerticalsPromptService, verticalsService: SiteVerticalsService, selection: @escaping (SiteVertical) -> Void) {
        self.segment = segment
        self.promptService = promptService
        self.verticalsService = verticalsService
        self.selection = selection

        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        table.layoutHeaderView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyTitle()
        setupBackground()
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchPromptIfNeeded()

        observeNetworkStatus()
        startListeningToKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopListeningToKeyboardNotifications()
        prompt = nil
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
    }

    private func fetchPromptIfNeeded() {
        // No need to obtain more than one prompt
        guard prompt == nil else {
            return
        }

        // This should never apply, but we have a Segment?
        guard let promptRequest = segment?.identifier else {
            let defaultPrompt = DefaultSiteVerticalsPrompt()
            setupTableHeaderWithPrompt(defaultPrompt)

            return
        }

        promptService.retrieveVerticalsPrompt(request: promptRequest) { [weak self] serverPrompt in
            guard let self = self else {
                return
            }

            let prompt: SiteVerticalsPrompt
            if let serverPrompt = serverPrompt {
                prompt = serverPrompt
            } else {
                prompt = DefaultSiteVerticalsPrompt()
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

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
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
            bottomConstraint,
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

    private func setupTable() {
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupConstraints()
        hideSeparators()

        setupTableDataProvider()
    }

    private func setupTableBackground() {
        table.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTableHeaderWithPrompt(_ prompt: SiteVerticalsPrompt) {
        self.prompt = prompt

        table.tableHeaderView = nil

        let header = TitleSubtitleTextfieldHeader(frame: .zero)
        header.setTitle(prompt.title)
        header.setSubtitle(prompt.subtitle)

        header.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        let placeholderText = prompt.hint
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(WPStyleGuide.grey())
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        header.textField.attributedPlaceholder = attributedPlaceholder

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
            self.selection(vertical)
        }

        self.tableViewProvider = VerticalsTableViewProvider(tableView: table, data: data, selectionHandler: handler)
    }

    private func setupTableSeparator() {
        table.separatorColor = WPStyleGuide.greyLighten20()
    }

    @objc
    private func textChanged(sender: UITextField) {
        guard let searchTerm = sender.text, searchTerm.isEmpty == false else {
            clearContent()
            return
        }
        performSearchIfNeeded(query: searchTerm)
    }
}

// MARK: - NetworkStatusDelegate

extension VerticalsWizardContent: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        isNetworkActive = active
    }
}

// MARK: - Keyboard management

private extension VerticalsWizardContent {
    struct Constants {
        static let bottomMargin: CGFloat = 0.0
        static let topMargin: CGFloat = 36.0
    }

    @objc
    func keyboardWillHide(_ notification: Foundation.Notification) {
        guard let payload = KeyboardInfo(notification) else { return }
        let animationDuration = payload.animationDuration

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
                        self?.table.contentInset = .zero
                        self?.table.scrollIndicatorInsets = .zero
                        self?.bottomConstraint.constant = Constants.bottomMargin
                        if let header = self?.table.tableHeaderView as? TitleSubtitleTextfieldHeader {
                            header.titleSubtitle.alpha = 1.0
                        }

            },
                       completion: nil)
    }

    @objc
    func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let payload = KeyboardInfo(notification) else { return }
        let keyboardScreenFrame = payload.frameEnd

        let convertedKeyboardFrame = view.convert(keyboardScreenFrame, from: nil)

        var constraintConstant = convertedKeyboardFrame.height

        if #available(iOS 11.0, *) {
            let bottomInset = view.safeAreaInsets.bottom
            constraintConstant -= bottomInset
        }

        let animationDuration = payload.animationDuration

        bottomConstraint.constant = constraintConstant
        view.setNeedsUpdateConstraints()

        let contentInsets = tableContentInsets(bottom: constraintConstant)

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
                        self?.table.contentInset = contentInsets
                        self?.table.scrollIndicatorInsets = contentInsets
                        if let header = self?.table.tableHeaderView as? TitleSubtitleTextfieldHeader {
                            header.titleSubtitle.alpha = 0.0
                        }

            },
                       completion: nil)
    }

    func startListeningToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func tableContentInsets(bottom: CGFloat) -> UIEdgeInsets {
        guard let header = table.tableHeaderView as? TitleSubtitleTextfieldHeader else {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: bottom, right: 0.0)
        }

        let textfieldFrame = header.textField.frame
        return UIEdgeInsets(top: (-1 * textfieldFrame.origin.y) + Constants.topMargin, left: 0.0, bottom: bottom, right: 0.0)
    }
}
