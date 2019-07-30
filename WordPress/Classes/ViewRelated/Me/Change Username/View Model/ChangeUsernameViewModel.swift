import Reachability
import WordPressFlux

class ChangeUsernameViewModel {
    typealias ReachabilityListener = () -> Void
    typealias KeyboardListener = (Foundation.Notification) -> Void
    typealias StateBlock = (AccountSettingsState, String) -> Void

    var username: String {
        return settings?.username ?? ""
    }
    var displayName: String {
        return settings?.displayName ?? ""
    }
    var paragraph: String {
        return Constants.paragraph
    }
    var formattedCreatedDate: String? {
        return accountService.defaultWordPressComAccount()?.dateCreated.mediumString()
    }
    var isReachable: Bool {
        return reachability?.isReachable() ?? false
    }
    var usernameIsValidToBeChanged: Bool {
        return store.validationSucceeded()
    }

    var reachabilityListener: ReachabilityListener?
    var keyboardListener: KeyboardListener?
    var validationListener: StateBlock?

    private let settings: AccountSettings?
    private let store: AccountSettingsStore
    private let scheduler = Scheduler(seconds: 0.5)
    private let reachability = Reachability.forInternetConnection()
    private let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var receipt: Receipt?
    private var saveUsernameBlock: StateBlock?
    private var currentUsername: String = ""

    init(service: AccountSettingsService?, settings: AccountSettings?) {
        self.settings = settings
        self.store = AccountSettingsStore(service: service)
        self.receipt = self.store.onStateChange { [weak self] (old, new) in
            if old.usernameValidationState != new.usernameValidationState {
                self?.validation(for: new.usernameValidationState)
            }
            if old.usernameSaveState != new.usernameSaveState {
                self?.saveUsernameBlock?(new.usernameSaveState, Constants.Error.saveUsername)
            }
        }
    }

    deinit {
        removeObserver()
    }

    func start() {
        addObservers()
        validation(for: .stationary)
    }

    func validate(username: String) {
        if username.isEmpty {
            validation(for: .failure(Constants.Error.emptyValue))
            return
        }

        if username == self.username {
            validation(for: .stationary)
            return
        }

        scheduler.debounce { [weak self] in
            self?.currentUsername = username
            self?.store.onDispatch(AccountSettingsAction.validate(username: username))
        }
    }

    func save(saveUsernameBlock: @escaping StateBlock) {
        self.saveUsernameBlock = saveUsernameBlock
        store.onDispatch(AccountSettingsAction.saveUsername(username: currentUsername))
    }
}

private extension ChangeUsernameViewModel {
    func addObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        let reachabilityBlock: NetworkReachable = { [weak self] reachability in
            self?.reachabilityListener?()
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
        keyboardListener?(notification)
    }

    func validation(for state: AccountSettingsState) {
        switch state {
        case .stationary:
            validationListener?(.stationary, String(format: Constants.Username.stationary, formattedCreatedDate ?? Date().mediumString()))
        case .success:
            validationListener?(state, String(format: Constants.Username.success, currentUsername))
        case .failure:
            validationListener?(state, state.failureMessage ?? Constants.Error.validateUsername)
        default:
            break
        }
    }

    enum Constants {
        static let paragraph = NSLocalizedString("You are about to change your username, which is currently %@. You will not be able to change your username back.\n\nIf you just want to change your display name, which is currently %@, you can do so under My Profile.\n\nChanging your username will also affect your Gravatar profile and IntenseDebate profile addresses.",
                                                comment: "Paragraph displayed in the footer. The placholders are for the current username and the current display name.")

        enum Username {
            static let stationary = NSLocalizedString("Joined %@", comment: "Change username textfield footer title. The placeholder is the date when the user has been created")
            static let success = NSLocalizedString("%@ is a valid username.", comment: "Success message when a typed username is valid. The placeholder indicates the validated username")
        }

        enum Error {
            static let validateUsername = NSLocalizedString("There was an error validating the username", comment: "Text displayed when there is a failure validating the username.")
            static let saveUsername = NSLocalizedString("There was an error saving the username", comment: "Text displayed when there is a failure saving the username.")
            static let emptyValue = NSLocalizedString("Username must be at least 4 characters.", comment: "Error displayed if the username input is an empty string")
        }
    }
}
