class ChangeUsernameViewController: UIViewController {
    typealias ChangeUsernameCompletionBlock = () -> Void

    private typealias TextfieldRow = ChangeUsernameTextfield
    private typealias LabelRow = ChangeUsernameLabel

    private let usernameTextfield = TextfieldRow.loadFromNib()
    private let usernameTextfieldFooter = LabelRow.loadFromNib()
    private let viewModel: ChangeUsernameViewModel
    private let completionBlock: ChangeUsernameCompletionBlock
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

    init(service: AccountSettingsService, settings: AccountSettings?, completionBlock: @escaping ChangeUsernameCompletionBlock) {
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
            DispatchQueue.main.async {
                self?.setNeedsSaveButtonIsEnabled()
            }
        }
        viewModel.keyboardListener = { [weak self] notification in
            DispatchQueue.main.async {
                self?.adjustForKeyboard(notification: notification)
            }
        }
        viewModel.validationListener = { [weak self] (state, text) in
            DispatchQueue.main.async {
                self?.setNeedsSaveButtonIsEnabled()
                self?.usernameTextfieldFooter.set(text: text, for: state)
            }
        }
        viewModel.start()
    }

    func setupUI() {
        navigationItem.title = Constants.username
        navigationItem.rightBarButtonItem = saveBarButtonItem

        footerLabel.alpha = 0.0

        setUsernameTextfield()
        setNeedsSaveButtonIsEnabled()
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
        footerLabel.attributedText = attributed(for: viewModel.paragraph,
                                                username: viewModel.username,
                                                displayName: viewModel.displayName)
        UIView.animate(withDuration: 0.3) {
            self.footerLabel.alpha = 1.0
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
        SVProgressHUD.show()
        viewModel.save() { [weak self] (state, error) in
            DispatchQueue.main.async {
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
    }

    func attributed(for text: String, username: String, displayName: String) -> NSAttributedString {
        let text = String(format: text, username, displayName)
        let font = WPStyleGuide.fontForTextStyle(.footnote)
        let bold = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)

        let attributed = NSMutableAttributedString(string: text, attributes: [.font: font])
        attributed.applyStylesToMatchesWithPattern("\\b\(username)|\\b\(displayName)", styles: [.font: bold])
        return attributed
    }

    enum Constants {
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")
        static let username = NSLocalizedString("Username", comment: "The header and main title")
    }
}
