class ChangeUsernameViewController: SignupUsernameTableViewController {
    typealias CompletionBlock = () -> Void

    private let viewModel: ChangeUsernameViewModel
    private let completionBlock: CompletionBlock
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()

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
        viewModel.suggestUsernames(for: searchTerm)
    }
}

private extension ChangeUsernameViewController {
    func setupViewModel() {
        let reloadSaveButton: ChangeUsernameViewModel.VoidListener = { [weak self] in
            self?.setNeedsSaveButtonIsEnabled()
        }
        viewModel.reachabilityListener = reloadSaveButton
        viewModel.selectedUsernameListener = reloadSaveButton
        viewModel.keyboardListener = { [weak self] notification in
            self?.adjustForKeyboard(notification: notification)
        }
        viewModel.suggestionsListener = { [weak self] state, suggestions in
            switch state {
            case .loading:
                SVProgressHUD.show(withStatus: Constants.Alert.loading)
            case .success:
                SVProgressHUD.dismiss()
                self?.suggestions = suggestions
                self?.reloadSuggestions()
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
        SVProgressHUD.show()
        viewModel.save() { [weak self] (state, error) in
            switch state {
            case .success:
                SVProgressHUD.dismiss()
                self?.completionBlock()
                self?.navigationController?.popViewController(animated: true)
            case .failure:
                SVProgressHUD.showError(withStatus: error)
            default:
                break
            }
        }
    }

    func changeUsernameConfirmationPrompt() -> UIAlertController {
        let alertController = UIAlertController(title: Constants.Alert.title,
                                                message: String(format: Constants.Alert.message, viewModel.selectedUsername),
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = Constants.Alert.confirm
        }
        alertController.addCancelActionWithTitle(Constants.Alert.cancel)
        alertController.addDefaultActionWithTitle(Constants.Alert.change, handler: { [weak alertController] _ in
            guard let textField = alertController?.textFields?.first,
                textField.text == self.viewModel.selectedUsername else {
                    DDLogInfo("Username confirmation failed")
                    return
            }
            DDLogInfo("User changes username")
            self.changeUsername()
        })
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
            static let message = NSLocalizedString("You are changing your Username to %@. Changing your username will also affect your Gravatar profile and IntenseDebate profile addresses. \nConfirm your new Username to continue.", comment: "Alert message.")
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button.")
            static let change = NSLocalizedString("Change Username", comment: "Change button.")
            static let confirm = NSLocalizedString("Confirm Username", comment: "Alert text field placeholder.")
        }
    }
}
