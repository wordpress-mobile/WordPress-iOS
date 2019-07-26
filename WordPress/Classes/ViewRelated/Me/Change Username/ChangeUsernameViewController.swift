import Reachability

class ChangeUsernameViewController: UIViewController {
    private let service: AccountSettingsService
    private let settings: AccountSettings?
    private let reachability = Reachability.forInternetConnection()
    private let usernameTextfield = ChangeUsernameTextfield.loadFromNib()
    private let usernameTextfieldFooter = ChangeUsernameLabel.loadFromNib()
    private let scheduler = Scheduler(seconds: 1.0)
    private var validatorState: State = .neutral
    private var confirmationState: State = .neutral
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()
    @IBOutlet private var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var footerTitle: UILabel!
    @IBOutlet private var footerText: UILabel!
    @IBOutlet private var containerView: UIStackView!

    init(service: AccountSettingsService, settings: AccountSettings?) {
        self.service = service
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeObserver()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        addObservers()
    }
}

private extension ChangeUsernameViewController {
    func setupUI() {
        navigationItem.title = Constants.title
        navigationItem.rightBarButtonItem = saveBarButtonItem

        containerView.addArrangedSubviews([ChangeUsernameLabel.label(text: Constants.Textfield.username.uppercased()),
                                           usernameTextfield])
        if let account = defaultAccount() {
            usernameTextfieldFooter.set(text: String(format: Constants.Textfield.date, account.dateCreated.mediumString()))
            containerView.addArrangedSubview(usernameTextfieldFooter)
        }
        setFooter()
        setNeedsSaveButtonIsEnabled(isReachable: reachability?.isReachable() ?? false)
    }

    func addObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        let reachabilityBlock: NetworkReachable = { [weak self] reachability in
            self?.setNeedsSaveButtonIsEnabled(isReachable: reachability?.isReachable() ?? false)
        }
        reachability?.reachableBlock = reachabilityBlock
        reachability?.unreachableBlock = reachabilityBlock
        reachability?.startNotifier()
    }

    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
        reachability?.stopNotifier()
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
        scheduler.debounce { [weak self] in
            self?.service.validateUsername(to: username, success: {
                self?.validationSucceeded()
            }) { error in
                self?.validationFailed(error: error.localizedDescription)
            }
        }
    }

    func validationSucceeded() {
        validatorState = .success

        usernameTextfieldFooter.set(text: "%@ is a valid username.", for: .success)
    }

    func validationFailed(error: String) {
        validatorState = .failure
        confirmationState = .failure

        usernameTextfieldFooter.set(text: error, for: .error)
    }

    func save() {

    }

    func setNeedsSaveButtonIsEnabled(isReachable: Bool) {
        saveBarButtonItem.isEnabled = isReachable && validatorState == .success && confirmationState == .success
    }

    func setFooter() {
        guard let username = settings?.username,
            let displayName = settings?.displayName else {
                footerTitle.isHidden = true
                footerText.isHidden = true
            return
        }
        footerTitle.text = Constants.Footer.title
        footerText.attributedText = attributed(for: Constants.Footer.text,
                                               username: username,
                                               displayName: displayName)
    }

    private func defaultAccount() -> WPAccount? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()
        return account
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
        static let title = NSLocalizedString("Change Username", comment: "Main title")
        static let description = NSLocalizedString("", comment: "Help text that describes how the password should be. It appears while editing the password")
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")

        enum Textfield {
            static let username = NSLocalizedString("Username", comment: "Change username textfield header title")
            static let date = NSLocalizedString("Joined %@", comment: "Change username textfield footer title. The placeholder is the date when the user has been created")
        }

        enum Footer {
            static let title = NSLocalizedString("Please Read Carefully", comment: "Title displayed in the footer")
            static let text = NSLocalizedString("You are about to change your username, which is currently %@. You will not be able to change your username back.\n\nIf you just want to change your display name, which is currently %@, you can do so under My Profile.\n\nChanging your username will also affect your Gravatar profile and IntenseDebate profile addresses.\n\nIf you would still like to change your username, please save your changes. Otherwise, hit the back button.",
                                                  comment: "Paragraph displayed in the footer. The placholders are for the current username and the current display name.")
        }
    }

    enum State {
        case neutral
        case success
        case failure
    }
}
