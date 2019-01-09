import UIKit
import WordPressKit

/// Contains the UI corresponding to the list of verticals
///
final class VerticalsWizardContent: UIViewController {

    // MARK: Properties

    private struct StyleConstants {
        static let rowHeight: CGFloat = 44.0
        static let separatorInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 0)
    }

    private let segment: SiteSegment?

    private let promptService: SiteVerticalsPromptService

    private let prompt: SiteVerticalsPrompt = DefaultSiteVerticalsPrompt()

    private let verticalsService: SiteVerticalsService

    private let selection: (SiteVertical) -> Void

    private let throttle = Scheduler(seconds: 1)

    @IBOutlet
    private weak var table: UITableView!

    private(set) var tableViewProvider: TableViewProvider?

    private lazy var bottomConstraint: NSLayoutConstraint = {
        return self.table.bottomAnchor.constraint(equalTo: self.view.prevailingLayoutGuide.bottomAnchor)
    }()

    private lazy var headerData: SiteCreationHeaderData = {
        return SiteCreationHeaderData(title: prompt.title, subtitle: prompt.subtitle)
    }()

    // MARK: VerticalsWizardContent

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

    override func viewDidLoad() {
        super.viewDidLoad()

        applyTitle()
        setupBackground()
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningToKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToKeyboardNotifications()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        table.layoutHeaderView()
    }

    // MARK: Private behavior

    private func applyTitle() {
        title = NSLocalizedString("1 of 3", comment: "Site creation. Step 2. Screen title")
    }

    private func clearContent() {
        throttle.cancel()

        guard let validDataProvider = tableViewProvider as? DefaultVerticalsTableViewProvider else {
            setupTableDataProvider()
            return
        }
        validDataProvider.data = []
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
        if let validDataProvider = tableViewProvider as? DefaultVerticalsTableViewProvider {
            validDataProvider.data = data
        } else {
            setupTableDataProvider(data)
        }
    }

    private func handleError(_ error: Error) {
        debugPrint("=== handling error===")
    }

    private func hideSeparators() {
        table.tableFooterView = UIView(frame: .zero)
    }

    private func registerCell(identifier: String) {
        let nib = UINib(nibName: identifier, bundle: nil)
        table.register(nib, forCellReuseIdentifier: identifier)
    }

    private func registerCells() {
        registerCell(identifier: VerticalsCell.cellReuseIdentifier())
        registerCell(identifier: NewVerticalCell.cellReuseIdentifier())
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupCellHeight() {
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = StyleConstants.rowHeight
        table.separatorInset = StyleConstants.separatorInset
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

    private func setupHeader() {
        let header = TitleSubtitleTextfieldHeader(frame: .zero)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

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

    private func setupTable() {
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupHeader()
        setupConstraints()
        hideSeparators()

        setupTableDataProvider()
    }

    private func setupTableDataProvider(_ data: [SiteVertical] = []) {
        self.tableViewProvider = DefaultVerticalsTableViewProvider(tableView: table, data: data) { [weak self] selectedVertical in
            guard let self = self, let vertical = selectedVertical else {
                return
            }
            self.selection(vertical)
        }
    }

    private func setupTableBackground() {
        table.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTableSeparator() {
        table.separatorColor = WPStyleGuide.greyLighten20()
    }

    private func performSearchIfNeeded(query: String) {
        guard !query.isEmpty else {
            return
        }

        throttle.throttle { [weak self] in
            self?.fetchVerticals(query)
        }
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
