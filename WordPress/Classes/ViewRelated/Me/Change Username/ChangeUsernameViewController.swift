class ChangeUsernameViewController: UIViewController {
    private typealias TextfieldRow = ChangeUsernameTextfield
    private typealias LabelRow = ChangeUsernameLabel

    private let usernameTextfield = TextfieldRow.loadFromNib()
    private let usernameTextfieldFooter = LabelRow.loadFromNib()
    private let confirmationTextfield = TextfieldRow.loadFromNib()
    private let confirmationTextfieldFooter = LabelRow.loadFromNib()
    private let viewModel: ChangeUsernameViewModel
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()
    @IBOutlet private var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var footerText: UILabel!
    @IBOutlet private var containerView: UIStackView!
    @IBOutlet private var textFieldContainerView: UIStackView!

    init(service: AccountSettingsService, settings: AccountSettings?) {
        self.viewModel = ChangeUsernameViewModel(service: service, settings: settings)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameTextfield.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        usernameTextfield.resignFirstResponder()
        confirmationTextfield.resignFirstResponder()
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
            DispatchQueue.main.async {
                self?.setNeedsSaveButtonIsEnabled()
                self?.usernameTextfieldFooter.set(text: text, for: state)
            }
        }
        viewModel.confirmationListener = { [weak self] (state, text) in
            DispatchQueue.main.async {
                self?.setNeedsSaveButtonIsEnabled()
                self?.confirmationTextfieldFooter.set(text: text, for: state)
            }
        }
        viewModel.start()
    }

    func setupUI() {
        navigationItem.title = Constants.title
        navigationItem.rightBarButtonItem = saveBarButtonItem

        setUsernameTextfield()
        setFooter()

        setNeedsSaveButtonIsEnabled()
    }

    func setNeedsSaveButtonIsEnabled() {
        saveBarButtonItem.isEnabled = viewModel.isReachable && viewModel.usernameIsValidToBeChanged
    }

    func setUsernameTextfield() {
        usernameTextfield.set(text: viewModel.username)
        usernameTextfield.textDidChange = { [weak self] text in
            self?.setConfirmationTextfieldIfNeeded()
            self?.validate(username: text)
        }

        let title = LabelRow.label(text: Constants.title.uppercased())
        containerView.insertArrangedSubview(title, at: 0)
        textFieldContainerView.addArrangedSubviews([usernameTextfield, usernameTextfieldFooter])
    }

    func setConfirmationTextfieldIfNeeded() {
        if confirmationTextfield.superview != nil {
            return
        }

        confirmationTextfield.textDidChange = { [weak self] text in
            self?.viewModel.confirm(username: text)
        }

        let title = LabelRow.label(text: Constants.Header.confirmation.uppercased())
        textFieldContainerView.addArrangedSubviews([title, confirmationTextfield, confirmationTextfieldFooter])
    }

    func setFooter() {
        footerText.attributedText = attributed(for: viewModel.paragraph,
                                               username: viewModel.username,
                                               displayName: viewModel.displayName)
    }

    func adjustForKeyboard(notification: Foundation.Notification) {
        let wrappedRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = view.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + view.frame.height, 0)
        scrollViewBottomConstraint.constant = bottomInset
        view.layoutIfNeeded()
    }

    func validate(username: String) {
        viewModel.validate(username: username)
    }

    func save() {

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
        static let title = NSLocalizedString("Change Username", comment: "Main title")

        enum Header {
            static let username = NSLocalizedString("Username", comment: "Change username textfield header title")
            static let confirmation = NSLocalizedString("Confirm Username", comment: "Confirm username textfield header title")
        }
    }
}
