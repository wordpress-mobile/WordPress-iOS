class ChangeUsernameViewController: UIViewController {
    private typealias TextfieldRow = ChangeUsernameTextfield
    private typealias LabelRow = ChangeUsernameLabel

    private let usernameTextfield = TextfieldRow.loadFromNib()
    private let usernameTextfieldFooter = LabelRow.loadFromNib()
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

    deinit {
        viewModel.removeObserver()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewModel()
        setupUI()
    }
}

private extension ChangeUsernameViewController {
    func setupViewModel() {
        viewModel.addObservers()
        viewModel.reachabilityListener = { [weak self] in
            self?.setNeedsSaveButtonIsEnabled()
        }
        viewModel.validationListener = { [weak self] (success, error) in
            DispatchQueue.main.async {
                if success {
                    self?.usernameTextfieldFooter.set(text: "%@ is a valid username.", for: .success)
                } else {
                    self?.usernameTextfieldFooter.set(text: error, for: .error)
                }
            }
        }
    }

    func setupUI() {
        navigationItem.title = Constants.Header.title
        navigationItem.rightBarButtonItem = saveBarButtonItem

        let title = LabelRow.label(text: Constants.Header.title.uppercased())
        containerView.insertArrangedSubview(title, at: 0)
        textFieldContainerView.addArrangedSubview(usernameTextfield)
        if let account = viewModel.defaultAccount {
            usernameTextfieldFooter.set(text: String(format: Constants.Username.footer, account.dateCreated.mediumString()))
            textFieldContainerView.addArrangedSubview(usernameTextfieldFooter)
        }
        setFooter()

        setNeedsSaveButtonIsEnabled()
    }

    @objc func adjustForKeyboard(notification: Foundation.Notification) {
        let wrappedRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = view.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + view.frame.height, 0)
        scrollViewBottomConstraint.constant = bottomInset
        view.layoutIfNeeded()
    }

    func validate(username: String) {

    }

    func save() {

    }

    func setNeedsSaveButtonIsEnabled() {
        saveBarButtonItem.isEnabled = viewModel.isReachable && viewModel.usernameIsValidToBeChanged
    }

    func setFooter() {
        footerText.attributedText = attributed(for: Constants.Header.text,
                                               username: viewModel.username,
                                               displayName: viewModel.displayName)
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
        static let separatorHeight: CGFloat = 1.0 / UIScreen.main.scale

        enum Username {
            static let header = NSLocalizedString("Username", comment: "Change username textfield header title")
            static let footer = NSLocalizedString("Joined %@", comment: "Change username textfield footer title. The placeholder is the date when the user has been created")
            static let success = NSLocalizedString("%@ is a valid username.", comment: "Success message when a typed username is valid. The placeholder indicates the validated username")
        }

        enum Confirmation {
            static let header = NSLocalizedString("Confirm Username", comment: "Confirm username textfield header title")
            static let footer = NSLocalizedString("Confirm new username", comment: "Confirm username textfield footer title.")
            static let success = NSLocalizedString("Thanks for confirming your new username!", comment: "Success message with the username confirmation")
            static let failure = NSLocalizedString("Please re-enter your new username to confirm it.", comment: "Failure message when the username confirmation fails")
        }

        enum Header {
            static let title = NSLocalizedString("Change Username", comment: "Main title")
            static let text = NSLocalizedString("You are about to change your username, which is currently %@. You will not be able to change your username back.\n\nIf you just want to change your display name, which is currently %@, you can do so under My Profile.\n\nChanging your username will also affect your Gravatar profile and IntenseDebate profile addresses.",
                                                  comment: "Paragraph displayed in the footer. The placholders are for the current username and the current display name.")
        }
    }
}
