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
        return store.validationSucceeded() && currentUsername == confirmationUsername
    }

    var reachabilityListener: ReachabilityListener?
    var keyboardListener: KeyboardListener?
    var confirmationListener: StateBlock?
    var validationListener: StateBlock?

    private let settings: AccountSettings?
    private let store: AccountSettingsStore
    private let scheduler = Scheduler(seconds: 1.0)
    private let reachability = Reachability.forInternetConnection()
    private let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var receipt: Receipt?
    private var currentUsername: String = ""
    private var confirmationUsername: String = ""

    init(service: AccountSettingsService?, settings: AccountSettings?) {
        self.settings = settings
        self.store = AccountSettingsStore(service: service)
        self.receipt = self.store.onStateChange { [weak self] (old, new) in
            if old.usernameValidationState != new.usernameValidationState {
                self?.validation(for: new.usernameValidationState)
                self?.confirmation(for: new.usernameValidationState)
            }
        }
    }

    deinit {
        removeObserver()
    }

    func start() {
        addObservers()
        validation(for: .stationary)
        confirmation(for: .stationary)
    }

    func validate(username: String) {
        currentUsername = username
        confirmation(for: store.validationState)
        scheduler.debounce { [weak self] in
            self?.store.onDispatch(AccountSettingsAction.validate(username: username))
        }
    }

    func confirm(username: String) {
        confirmationUsername = username
        confirmation(for: store.validationState)
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
        case .stationary, .loading:
            validationListener?(.stationary, String(format: Constants.Username.stationary, formattedCreatedDate ?? Date().mediumString()))
        case .success:
            validationListener?(state, String(format: Constants.Username.success, currentUsername))
        case .failure:
            validationListener?(state, state.failureMessage ?? "")
        }
    }

    func confirmation(for validationState: AccountSettingsState) {
        switch validationState {
        case .stationary, .loading, .failure:
            confirmationListener?(.stationary, Constants.Confirmation.stationary)
        case .success:
            confirmationListener?(usernameIsValidToBeChanged ? .success : .failure(nil),
                                  usernameIsValidToBeChanged ? Constants.Confirmation.success : Constants.Confirmation.failure)
        }
    }

    enum Constants {
        static let paragraph = NSLocalizedString("You are about to change your username, which is currently %@. You will not be able to change your username back.\n\nIf you just want to change your display name, which is currently %@, you can do so under My Profile.\n\nChanging your username will also affect your Gravatar profile and IntenseDebate profile addresses.",
                                                comment: "Paragraph displayed in the footer. The placholders are for the current username and the current display name.")
        enum Username {
            static let stationary = NSLocalizedString("Joined %@", comment: "Change username textfield footer title. The placeholder is the date when the user has been created")
            static let success = NSLocalizedString("%@ is a valid username.", comment: "Success message when a typed username is valid. The placeholder indicates the validated username")
        }

        enum Confirmation {
            static let stationary = NSLocalizedString("Confirm new username", comment: "Confirm username textfield footer title.")
            static let success = NSLocalizedString("Thanks for confirming your new username!", comment: "Success message with the username confirmation")
            static let failure = NSLocalizedString("Please re-enter your new username to confirm it.", comment: "Failure message when the username confirmation fails")
        }
    }
}
