class ChangeUsernameViewController: UIViewController {
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
    @IBOutlet private var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private var tableView: UITableView!

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
        super.viewWillAppear(animated)
        viewModel.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }
}

private extension ChangeUsernameViewController {
    func setupViewModel() {
        viewModel.reachabilityListener = { [weak self] in
            self?.setNeedsSaveButtonIsEnabled()
        }
        viewModel.keyboardListener = { [weak self] notification in
            self?.adjustForKeyboard(notification: notification)
        }
        viewModel.suggestionsListener = { state, suggestions in

        }
    }

    func setupUI() {
        navigationItem.title = Constants.username
        navigationItem.rightBarButtonItem = self.saveBarButtonItem

        WPStyleGuide.configureColors(view: view, tableView: tableView)

        setNeedsSaveButtonIsEnabled()
    }

    func setupBackgroundTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on(call: { [weak self] (gesture) in
            self?.view.endEditing(true)
        })
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }

    func setNeedsSaveButtonIsEnabled() {
        saveBarButtonItem.isEnabled = viewModel.isReachable && viewModel.usernameIsValidToBeChanged
    }

    func adjustForKeyboard(notification: Foundation.Notification) {
        let wrappedRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = view.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + view.frame.height, 0)
        bottomConstraint.constant = bottomInset
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
                                                message: Constants.Alert.message,
                                                preferredStyle: .alert)
        alertController.addCancelActionWithTitle(Constants.Alert.cancel)
        alertController.addDefaultActionWithTitle(Constants.Alert.change, handler: { _ in
            DDLogInfo("User changes username")
            self.changeUsername()
        })
        DDLogInfo("Prompting user for confirmation of change username")
        return alertController
    }

    enum Constants {
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")
        static let username = NSLocalizedString("Username", comment: "The header and main title")

        enum Alert {
            static let title = NSLocalizedString("Careful!", comment: "Alert title.")
            static let message = NSLocalizedString("You are changing your Username to %@. Changing your username will also affect your Gravatar profile and IntenseDebate profile addresses. \nConfirm your new Username to continue.", comment: "Alert message.")
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button.")
            static let change = NSLocalizedString("Change Username", comment: "Change button.")
        }
    }
}
