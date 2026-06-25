import Combine
import SVProgressHUD
import UIKit
import WordPressKit
import WordPressUI

final class ChangeUsernameViewController: UITableViewController {
    typealias CompletionBlock = (String?) -> Void

    private let viewModel: ChangeUsernameViewModel
    private let completionBlock: CompletionBlock
    private var suggestions: [String] = []
    private var selectedCell: UITableViewCell?
    private var searchCount: Int = 0
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()

    private var confirmationTextObserver: AnyCancellable?
    private weak var confirmationController: UIAlertController? {
        didSet {
            observeConfirmationTextField()
        }
    }

    init(service: AccountSettingsService, settings: AccountSettings?, completionBlock: @escaping CompletionBlock) {
        self.viewModel = ChangeUsernameViewModel(service: service, settings: settings)
        self.completionBlock = completionBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        trackViewLoaded()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.directionalLayoutMargins = WPStyleGuide.edgeInsetForLoginTextFields()

        setupViewModel()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()

        trackViewDismissed()
    }

    private func startSearch(for searchTerm: String) {
        saveBarButtonItem.isEnabled = false
        viewModel.suggestUsernames(for: searchTerm, reloadingAllSections: false)

        trackSearchPerformed()
    }
}

// MARK: - UITableViewDataSource

extension ChangeUsernameViewController {
    fileprivate enum Sections: Int {
        case titleAndDescription = 0
        case searchField = 1
        case suggestions = 2

        static var count: Int {
            suggestions.rawValue + 1
        }
    }

    private enum SuggestionStyles {
        static let indentationWidth: CGFloat = 20.0
        static let indentationLevel = 1
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.titleAndDescription.rawValue:
            return 1
        case Sections.searchField.rawValue:
            return 1
        case Sections.suggestions.rawValue:
            return suggestions.count + 1
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
            if indexPath.row == 0 {
                let isChecked = viewModel.selectedUsername.isEmpty || viewModel.selectedUsername == viewModel.username
                cell = suggestionCell(username: viewModel.username, checked: isChecked)
            } else {
                let suggestion = suggestions[indexPath.row - 1]
                cell = suggestionCell(username: suggestion, checked: suggestion == viewModel.selectedUsername)
            }
            if cell.accessoryType == .checkmark {
                selectedCell = cell
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Sections.suggestions.rawValue {
            let footer = UIView()
            footer.backgroundColor = UIAppColor.neutral(.shade10)
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUsername: String
        switch indexPath.section {
        case Sections.suggestions.rawValue:
            if indexPath.row == 0 {
                selectedUsername = viewModel.username
            } else {
                selectedUsername = suggestions[indexPath.row - 1]
            }
        default:
            return
        }

        viewModel.usernameSelected(selectedUsername)

        tableView.deselectSelectedRowWithAnimation(true)

        // Uncheck the previously selected cell.
        if let selectedCell {
            selectedCell.accessoryType = .none
        }

        // Check the currently selected cell.
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            selectedCell = cell
        }
    }

    // MARK: table view cells

    private func titleAndDescriptionCell() -> UITableViewCell {
        let cell = ChangeUsernameHeaderCell(description: viewModel.headerDescription())
        cell.selectionStyle = .none
        return cell
    }

    private func searchFieldCell() -> SearchFieldCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFieldCell.reuseIdentifier)
                as? SearchFieldCell
        else {
            fatalError()
        }

        cell.placeholder = NSLocalizedString(
            "Type a keyword for more ideas",
            comment: "Placeholder text for the username suggestions search field on the Change Username screen."
        )
        cell.selectionStyle = .none
        cell.onSearch = { [weak self] searchTerm in
            self?.startSearch(for: searchTerm)
        }

        return cell
    }

    private func suggestionCell(username: String, checked: Bool) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.textLabel?.text = username
        cell.textLabel?.textColor = UIAppColor.neutral(.shade70)

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byCharWrapping

        cell.indentationWidth = SuggestionStyles.indentationWidth
        cell.indentationLevel = SuggestionStyles.indentationLevel

        if checked {
            cell.accessoryType = .checkmark
        }
        return cell
    }
}

private extension ChangeUsernameViewController {
    func setupViewModel() {
        let reloadSaveButton: ChangeUsernameViewModel.Listener = { [weak self] in
            self?.setNeedsSaveButtonIsEnabled()
        }
        viewModel.reachabilityListener = reloadSaveButton
        viewModel.selectedUsernameListener = reloadSaveButton
        viewModel.keyboardListener = { [weak self] notification in
            self?.adjustForKeyboard(notification: notification)
        }
        viewModel.suggestionsListener = { [weak self] state, suggestions, reloadAllSections in
            switch state {
            case .loading:
                self?.showLoader()
            case .success:
                if suggestions.isEmpty {
                    WPAppAnalytics.track(.accountSettingsChangeUsernameSuggestionsFailed)
                }
                self?.hideLoader()
                self?.suggestions = suggestions
                self?.reloadSections(includingAllSections: reloadAllSections)
            default:
                break
            }
        }
    }

    func setupUI() {
        navigationItem.title = Constants.username
        navigationItem.rightBarButtonItems = [saveBarButtonItem]

        tableView.register(SearchFieldCell.self, forCellReuseIdentifier: SearchFieldCell.reuseIdentifier)
        setupBackgroundTapGestureRecognizer()
        setNeedsSaveButtonIsEnabled()
    }

    func setupBackgroundTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on(call: { [weak self] _ in
            self?.view.endEditing(true)
        })
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }

    func reloadSections(includingAllSections: Bool = true) {
        DispatchQueue.main.async {
            let set =
                includingAllSections
                ? IndexSet(integersIn: Sections.searchField.rawValue...Sections.suggestions.rawValue)
                : IndexSet(integer: Sections.suggestions.rawValue)
            self.tableView.reloadSections(set, with: .automatic)
        }
    }

    func showLoader() {
        searchCell?.showLoader()
    }

    func hideLoader() {
        searchCell?.hideLoader()
    }

    var searchCell: SearchFieldCell? {
        tableView.cellForRow(at: IndexPath(row: 0, section: Sections.searchField.rawValue)) as? SearchFieldCell
    }

    // MARK: - Tracking

    func trackViewLoaded() {
        WPAnalytics.track(.changeUsernameDisplayed, properties: ["source": Constants.analyticsSource])
    }

    func trackViewDismissed() {
        WPAnalytics.track(.changeUsernameDismissed, properties: ["source": Constants.analyticsSource])
    }

    func trackSearchPerformed() {
        searchCount += 1

        WPAnalytics.track(
            .changeUsernameSearchPerformed,
            properties: ["search_count": searchCount, "source": Constants.analyticsSource]
        )
    }

    func setNeedsSaveButtonIsEnabled() {
        saveBarButtonItem.isEnabled = viewModel.isReachable && viewModel.usernameIsValidToBeChanged
    }

    func adjustForKeyboard(notification: Foundation.Notification) {
        let wrappedRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = view.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + view.frame.height, 0)
        var insets = tableView.contentInset
        insets.bottom = bottomInset
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }

    func save() {
        let controller = changeUsernameConfirmationPrompt()
        present(controller, animated: true)
        confirmationController = controller
    }

    func changeUsername() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()

        viewModel.save() { [weak self] state, error in
            SVProgressHUD.setDefaultMaskType(.none)
            switch state {
            case .success:
                WPAppAnalytics.track(.accountSettingsChangeUsernameSucceeded)
                SVProgressHUD.dismiss()
                self?.completionBlock(self?.viewModel.selectedUsername)
                self?.navigationController?.popViewController(animated: true)
            case .failure:
                WPAppAnalytics.track(.accountSettingsChangeUsernameFailed)
                SVProgressHUD.showError(withStatus: error)
            default:
                break
            }
        }
    }

    func changeUsernameConfirmationPrompt() -> UIAlertController {
        let alertController = UIAlertController(
            title: Constants.Alert.title,
            message: "",
            preferredStyle: .alert
        )
        alertController.addAttributeMessage(
            String(format: Constants.Alert.message, viewModel.selectedUsername),
            highlighted: viewModel.selectedUsername
        )
        alertController.addCancelActionWithTitle(
            Constants.Alert.cancel,
            handler: { _ in
                DDLogInfo("User cancelled alert")
            }
        )
        let action = alertController.addDefaultActionWithTitle(
            Constants.Alert.change,
            handler: { [weak alertController, weak self] _ in
                guard let self, let alertController else { return }
                guard let textField = alertController.textFields?.first,
                    textField.text == self.viewModel.selectedUsername
                else {
                    DDLogInfo("Username confirmation failed")
                    return
                }
                DDLogInfo("User changes username")
                self.changeUsername()
            }
        )
        action.isEnabled = false
        alertController.addTextField { textField in
            textField.placeholder = Constants.Alert.confirm
        }
        DDLogInfo("Prompting user for confirmation of change username")
        return alertController
    }

    func observeConfirmationTextField() {
        confirmationTextObserver?.cancel()
        confirmationTextObserver = nil

        guard let confirmationController,
            let textField = confirmationController.textFields?.first
        else {
            return
        }

        // We need to add another condition to check if the text field is the username confirmation text field, if there
        // are more than one text field in the prompt.
        assert(confirmationController.textFields?.count == 1, "There should be only one text field in the prompt")

        confirmationTextObserver = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: textField)
            .sink(receiveValue: { [weak self] in
                self?.handleTextDidChangeNotification($0)
            })
    }

    func handleTextDidChangeNotification(_ notification: Foundation.Notification) {
        guard notification.name == UITextField.textDidChangeNotification,
            let confirmationController,
            let textField = notification.object as? UITextField
        else {
            DDLogInfo("The notification is not sent from the text field within the change username confirmation prompt")
            return
        }

        let actions = confirmationController.actions.filter({ $0.title == Constants.Alert.change })
        precondition(actions.count == 1, "More than one 'Change username' action found")
        let changeUsernameAction = actions.first

        let enabled = textField.text?.isEmpty == false && textField.text == self.viewModel.selectedUsername
        changeUsernameAction?.isEnabled = enabled
        textField.textColor = enabled ? UIAppColor.success : UIColor.label
    }

    enum Constants {
        static let analyticsSource = "account_settings"
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")
        static let username = NSLocalizedString("Username", comment: "The header and main title")

        enum Alert {
            static let title = NSLocalizedString("Careful!", comment: "Alert title.")
            static let message = NSLocalizedString(
                "You are changing your username to %@. Changing your username will also affect your Gravatar profile and IntenseDebate profile addresses. \nConfirm your new username to continue.",
                comment: "Alert message."
            )
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button.")
            static let change = NSLocalizedString("Change username", comment: "Change button.")
            static let confirm = NSLocalizedString("Confirm username", comment: "Alert text field placeholder.")
        }
    }
}

// MARK: - Header cell

/// Replaces the WordPressAuthenticator `LoginSocialErrorCell` for the description-only
/// header usage, replicating its visual output.
private final class ChangeUsernameHeaderCell: UITableViewCell {
    init(description: NSAttributedString) {
        super.init(style: .default, reuseIdentifier: nil)

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = description
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.topMargin),
            contentView.bottomAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: Metrics.bottomMargin
            ),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.minimumHeight)
        ])

        backgroundColor = .systemGroupedBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Metrics {
        // `LoginSocialErrorCell` stacked an empty title label above the description with
        // 15pt spacing inside 20pt vertical margins; the empty title collapses to zero
        // height, leaving 35pt above the description.
        static let topMargin: CGFloat = 35
        static let bottomMargin: CGFloat = 20
        static let minimumHeight: CGFloat = 14
    }
}

// MARK: - Search field cell

/// Replaces the WordPressAuthenticator `SearchTableViewCell`, replicating its visual
/// output with a plain `UITextField`.
private final class SearchFieldCell: UITableViewCell {
    static let reuseIdentifier = "SearchFieldCell"

    /// Called with the search term when the user taps the Search return key, and with
    /// an empty string when the field is cleared (matching the original cell, which ran
    /// with `liveSearch = false`).
    var onSearch: ((String) -> Void)?

    var placeholder: String? {
        get {
            textField.placeholder
        }
        set {
            guard let newValue, let font = textField.font else {
                textField.placeholder = newValue
                return
            }
            textField.attributedPlaceholder = NSAttributedString(
                string: newValue,
                attributes: [.foregroundColor: UIColor.tertiaryLabel, .font: font]
            )
        }
    }

    private let textField = UITextField()
    private let iconView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .systemGroupedBackground

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.font = .systemFont(ofSize: Metrics.fontSize)
        textField.returnKeyType = .search
        textField.clearButtonMode = .whileEditing
        textField.accessibilityIdentifier = "Search field"
        textField.delegate = self
        contentView.addSubview(textField)

        iconView.image = UIImage(named: "icon-post-search-highlight")?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = .tertiaryLabel
        iconView.frame = CGRect(
            x: Metrics.iconLeadingInset,
            y: (Metrics.fieldHeight - Metrics.iconSize) / 2,
            width: Metrics.iconSize,
            height: Metrics.iconSize
        )
        let leadingView = UIView(
            frame: CGRect(x: 0, y: 0, width: Metrics.leadingViewWidth, height: Metrics.fieldHeight)
        )
        leadingView.addSubview(iconView)
        spinner.center = iconView.center
        leadingView.addSubview(spinner)
        textField.leftView = leadingView
        textField.leftViewMode = .always

        let topHairline = makeHairline()
        let bottomHairline = makeHairline()

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: Metrics.bottomGap),
            textField.heightAnchor.constraint(equalToConstant: Metrics.fieldHeight),

            topHairline.topAnchor.constraint(equalTo: textField.topAnchor),
            bottomHairline.bottomAnchor.constraint(equalTo: textField.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoader() {
        spinner.startAnimating()
        iconView.alpha = 0
    }

    func hideLoader() {
        spinner.stopAnimating()
        iconView.alpha = 1
    }

    private func makeHairline() -> UIView {
        let hairline = UIView()
        hairline.translatesAutoresizingMaskIntoConstraints = false
        hairline.backgroundColor = .systemGray3
        contentView.addSubview(hairline)
        NSLayoutConstraint.activate([
            hairline.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: Metrics.hairlineHeight)
        ])
        return hairline
    }

    private enum Metrics {
        static let fieldHeight: CGFloat = 44
        static let bottomGap: CGFloat = 10
        // The legacy field's xib nominally used 14pt, but `WPWalkthroughTextField`'s
        // `setSecureTextEntry:` override reset the font to 16pt during nib decoding,
        // so 16pt is what actually rendered (verified by screenshot measurement).
        static let fontSize: CGFloat = 16
        static let iconSize: CGFloat = 22
        // The original `SearchTableViewCell` laid the icon out 20pt from the leading
        // edge (its content inset) with the text starting at x = 50; the left view's
        // width reproduces that text origin (20pt inset + 22pt icon + 8pt gap).
        static let iconLeadingInset: CGFloat = 20
        static let leadingViewWidth: CGFloat = 50
        // `LoginTextField.draw` set a line width on the bezier path but stroked via
        // `CGContextStrokePath`, which uses the context's default 1pt width instead;
        // clipped at the bounds edge, half of that stroke was visible.
        static let hairlineHeight: CGFloat = 0.5
    }
}

extension SearchFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchText = textField.text {
            onSearch?(searchText)
        }
        return false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        onSearch?("")
        return true
    }
}

fileprivate extension UIAlertController {
    func addAttributeMessage(_ message: String, highlighted text: String) {
        let paragraph = String(format: message, text)
        let font = WPStyleGuide.fontForTextStyle(.footnote)
        let bold = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)

        let attributed = NSMutableAttributedString(string: paragraph, attributes: [.font: font])
        attributed.applyStylesToMatchesWithPattern("\\b\(text)", styles: [.font: bold])
        setValue(attributed, forKey: "attributedMessage")
    }
}
