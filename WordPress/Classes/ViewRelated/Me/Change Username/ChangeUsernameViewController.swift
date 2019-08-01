class ChangeUsernameViewController: UIViewController {
    typealias CompletionBlock = () -> Void

    private typealias TextfieldRow = ChangeUsernameTextfield
    private typealias LabelRow = ChangeUsernameLabel

    private let usernameTextfield = TextfieldRow.loadFromNib()
    private let usernameTextfieldFooter = LabelRow.loadFromNib()
    private let viewModel: ChangeUsernameViewModel
    private let completionBlock: CompletionBlock
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()
    @IBOutlet private var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var container: UIStackView!
    @IBOutlet private var validationContainer: UIStackView!
    @IBOutlet private var footerLabel: UILabel!

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        usernameTextfield.resignFirstResponder()
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
        viewModel.validationListener = { [weak self] (state, text) in
            self?.setNeedsSaveButtonIsEnabled()
            self?.usernameTextfieldFooter.set(text: text, for: state)
        }
        viewModel.start()
    }

    func setupUI() {
        navigationItem.title = Constants.username

        footerLabel.alpha = 0.0

        setUsernameTextfield()
    }

    func setNeedsSaveButtonIsEnabled() {
        saveBarButtonItem.isEnabled = viewModel.isReachable && viewModel.usernameIsValidToBeChanged
    }

    func setUsernameTextfield() {
        usernameTextfield.set(text: viewModel.username)
        usernameTextfield.textDidBeginEditing = { [weak self] _ in
            self?.setFooterIfNeeded()
        }
        usernameTextfield.textDidChange = { [weak self] text in
            self?.validate(username: text)
        }

        let title = LabelRow.label(text: Constants.username.uppercased())
        container.insertArrangedSubview(title, at: 0)
        validationContainer.addArrangedSubviews([usernameTextfield, usernameTextfieldFooter])
    }

    func setFooterIfNeeded() {
        guard footerLabel.alpha == 0.0 else {
            return
        }

        footerLabel.attributedText = attributed(username: viewModel.username,
                                                displayName: viewModel.displayName)
        UIView.animate(withDuration: 0.3, animations: {
            self.footerLabel.alpha = 1.0
            self.navigationItem.rightBarButtonItem = self.saveBarButtonItem
        }) { _ in
            self.setNeedsSaveButtonIsEnabled()
        }
    }

    func adjustForKeyboard(notification: Foundation.Notification) {
        let wrappedRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = view.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + view.frame.height, 0)
        scrollViewBottomConstraint.constant = bottomInset
    }

    func validate(username: String) {
        viewModel.validate(username: username)
    }

    func save() {
        usernameTextfield.resignFirstResponder()
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

    func attributed(username: String, displayName: String) -> NSAttributedString {
        let text = String(format: Constants.paragraph, username, Constants.highlight, displayName)
        let font = WPStyleGuide.fontForTextStyle(.footnote)
        let bold = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)

        let attributed = NSMutableAttributedString(string: text, attributes: [.font: font])
        attributed.applyStylesToMatchesWithPattern("\\b\(username)|\\b\(displayName)", styles: [.font: bold])
        attributed.addAttributes([.underlineStyle: NSNumber(value: 1), .font: bold],
                                 range: (text as NSString).range(of: Constants.highlight))
        return attributed
    }

    enum Constants {
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")
        static let username = NSLocalizedString("Username", comment: "The header and main title")
        static let highlight = NSLocalizedString("You will not be able to change your username back.", comment: "Paragraph text that needs to be highlighted")
        static let paragraph = NSLocalizedString("You are about to change your username, which is currently %@. %@\n\nIf you just want to change your display name, which is currently %@, you can do so under My Profile.\n\nChanging your username will also affect your Gravatar profile and IntenseDebate profile addresses.",
                                                 comment: "Paragraph displayed in the footer. The placholders are for the current username, highlight text and the current display name.")
        enum Alert {
            static let title = NSLocalizedString("Careful!", comment: "Alert title.")
            static let message = NSLocalizedString("Are you sure you want to change your username? You will not be able to change it back.", comment: "Alert message.")
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button.")
            static let change = NSLocalizedString("Change", comment: "Change button.")
        }
    }
}
