import Reachability

class ChangeUsernameViewModel {
    var username: String {
        return settings?.username ?? ""
    }
    var displayName: String {
        return settings?.displayName ?? ""
    }
    var isReachable: Bool {
        return reachability?.isReachable() ?? false
    }
    var usernameIsValidToBeChanged: Bool {
        return validatorState == .success && confirmationState == .success
    }
    var defaultAccount: WPAccount? {
        return accountService.defaultWordPressComAccount()
    }

    var reachabilityListener: (() -> Void)?
    var validationListener: ((Bool, String) -> Void)?

    private weak var service: AccountSettingsService?
    private let settings: AccountSettings?
    private let scheduler = Scheduler(seconds: 1.0)
    private let reachability = Reachability.forInternetConnection()
    private let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var validatorState: State = .neutral
    private var confirmationState: State = .neutral

    init(service: AccountSettingsService?, settings: AccountSettings?) {
        self.service = service
        self.settings = settings
    }

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

    func validate(username: String) {
        scheduler.debounce { [weak self] in
            self?.service?.validateUsername(to: username, success: {
                self?.validationListener?(true, "")
            }) { error in
                self?.validationListener?(false, error.localizedDescription)
            }
        }
    }

    enum State {
        case neutral
        case success
        case failure
    }
}

private extension ChangeUsernameViewModel {
    @objc func adjustForKeyboard(notification: Foundation.Notification) {

    }
}
