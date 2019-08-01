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
            DispatchQueue.main.async {
                if old.usernameValidationState != new.usernameValidationState {
                    self?.validation(for: new.usernameValidationState)
                }
                if old.usernameSaveState != new.usernameSaveState {
                    self?.saveUsernameBlock?(new.usernameSaveState, Constants.Error.saveUsername)
                }
            }
        }
    }

    deinit {
        removeObserver()
    }

    func start() {
        addObservers()
        validation(for: .idle)
    }

    func validate(username: String) {
        if usernameIsValid(username) {
            scheduler.debounce { [weak self] in
                self?.currentUsername = username
                self?.store.onDispatch(AccountSettingsAction.validate(username: username))
            }
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
            DispatchQueue.main.async {
                self?.reachabilityListener?()
            }
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

    func usernameIsValid(_ username: String) -> Bool {
        if username.isEmpty {
            validation(for: .failure(Constants.Error.emptyValue))
            return false
        }

        if username == self.username {
            validation(for: .idle)
            return false
        }

        if !username.isAlphanumeric {
            validation(for: .failure(Constants.Error.alphanumeric))
            return false
        }

        return true
    }

    func validation(for state: AccountSettingsState) {
        DispatchQueue.main.async {
            switch state {
            case .idle:
                self.validationListener?(.idle, String(format: Constants.Username.stationary, self.formattedCreatedDate ?? Date().mediumString()))
            case .success:
                self.validationListener?(state, String(format: Constants.Username.success, self.currentUsername))
            case .failure:
                self.validationListener?(state, state.failureMessage ?? Constants.Error.validateUsername)
            default:
                break
            }
        }
    }

    enum Constants {
        enum Username {
            static let stationary = NSLocalizedString("Joined %@", comment: "Change username textfield footer title. The placeholder is the date when the user has been created")
            static let success = NSLocalizedString("%@ is a valid username.", comment: "Success message when a typed username is valid. The placeholder indicates the validated username")
        }

        enum Error {
            static let validateUsername = NSLocalizedString("There was an error validating the username", comment: "Text displayed when there is a failure validating the username.")
            static let saveUsername = NSLocalizedString("There was an error saving the username", comment: "Text displayed when there is a failure saving the username.")
            static let emptyValue = NSLocalizedString("Username must be at least 4 characters.", comment: "Error displayed if the username input is an empty string")
            static let alphanumeric = NSLocalizedString("Username can only contain lowercase letters (a-z) and numbers.", comment: "Error displayed if the username doesn't contain numbers or digits")
        }
    }
}

private extension String {
    var isAlphanumeric: Bool {
        return range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
