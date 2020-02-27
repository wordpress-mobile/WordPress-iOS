class ChangeUsernameViewController: SignupUsernameTableViewController {
    typealias CompletionBlock = (String?) -> Void

    private let viewModel: ChangeUsernameViewModel
    private let completionBlock: CompletionBlock
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()
    private var changeUsernameAction: UIAlertAction?

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
        setupViewModel()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        viewModel.start()
    }

    override func buildHeaderDescription() -> NSAttributedString {
        return viewModel.headerDescription()
    }

    override func startSearch(for searchTerm: String) {
        saveBarButtonItem.isEnabled = false
        viewModel.suggestUsernames(for: searchTerm, reloadingAllSections: false)
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
                SVProgressHUD.show(withStatus: Constants.Alert.loading)
            case .success:
                if suggestions.isEmpty {
                    WPAppAnalytics.track(.accountSettingsChangeUsernameSuggestionsFailed)
                }
                SVProgressHUD.dismiss()
                self?.suggestions = suggestions
                self?.reloadSections(includingAllSections: reloadAllSections)
            default:
                break
            }
        }
        currentUsername = viewModel.username
        delegate = viewModel
    }

    func setupUI() {
        navigationItem.title = Constants.username
        navigationItem.rightBarButtonItems = [saveBarButtonItem]

        registerNibs()
        setupBackgroundTapGestureRecognizer()
        setNeedsSaveButtonIsEnabled()
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
        present(changeUsernameConfirmationPrompt(), animated: true)
    }

    func changeUsername() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()

        viewModel.save() { [weak self] (state, error) in
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
        let alertController = UIAlertController(title: Constants.Alert.title,
                                                message: "",
                                                preferredStyle: .alert)
        alertController.addAttributeMessage(String(format: Constants.Alert.message, viewModel.selectedUsername),
                                            highlighted: viewModel.selectedUsername)
        alertController.addCancelActionWithTitle(Constants.Alert.cancel, handler: { [weak alertController] _ in
            if let textField = alertController?.textFields?.first {
                NotificationCenter.default.removeObserver(textField, name: UITextField.textDidChangeNotification, object: nil)
            }
            DDLogInfo("User cancelled alert")
        })
        changeUsernameAction = alertController.addDefaultActionWithTitle(Constants.Alert.change, handler: { [weak alertController] _ in
            guard let textField = alertController?.textFields?.first,
                textField.text == self.viewModel.selectedUsername else {
                    DDLogInfo("Username confirmation failed")
                    return
            }
            DDLogInfo("User changes username")
            NotificationCenter.default.removeObserver(textField, name: UITextField.textDidChangeNotification, object: nil)
            self.changeUsername()
        })
        changeUsernameAction?.isEnabled = false
        alertController.addTextField { [weak self] textField in
            textField.placeholder = Constants.Alert.confirm
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification,
                                                   object: textField,
                                                   queue: .main) {_ in
                                                    if let text = textField.text,
                                                        !text.isEmpty,
                                                        let username = self?.viewModel.selectedUsername,
                                                        text == username {
                                                        self?.changeUsernameAction?.isEnabled = true
                                                        textField.textColor = .success
                                                        return
                                                    }
                                                    self?.changeUsernameAction?.isEnabled = false
                                                    textField.textColor = .text
            }
        }
        DDLogInfo("Prompting user for confirmation of change username")
        return alertController
    }

    enum Constants {
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")
        static let username = NSLocalizedString("Username", comment: "The header and main title")
        static let cellIdentifier = "SearchTableViewCell"

        enum Alert {
            static let loading = NSLocalizedString("Loading usernames", comment: "Shown while the app waits for the username suggestions web service to return during the site creation process.")
            static let title = NSLocalizedString("Careful!", comment: "Alert title.")
            static let message = NSLocalizedString("You are changing your username to %@. Changing your username will also affect your Gravatar profile and IntenseDebate profile addresses. \nConfirm your new username to continue.", comment: "Alert message.")
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button.")
            static let change = NSLocalizedString("Change username", comment: "Change button.")
            static let confirm = NSLocalizedString("Confirm username", comment: "Alert text field placeholder.")
        }
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
