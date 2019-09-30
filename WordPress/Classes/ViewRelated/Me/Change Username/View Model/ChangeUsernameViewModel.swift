import Reachability
import WordPressFlux

class ChangeUsernameViewModel {
    typealias Listener = () -> Void
    typealias KeyboardListener = (Foundation.Notification) -> Void
    typealias SuggestionsListener = (AccountSettingsState, [String], Bool) -> Void
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
        return selectedUsername != username && !selectedUsername.isEmpty
    }

    var reachabilityListener: Listener?
    var selectedUsernameListener: Listener?
    var keyboardListener: KeyboardListener?
    var suggestionsListener: SuggestionsListener?
    var selectedUsername: String = "" {
        didSet {
            DispatchQueue.main.async {
                self.selectedUsernameListener?()
            }
        }
    }

    private let settings: AccountSettings?
    private let store: AccountSettingsStore
    private let reachability = Reachability.forInternetConnection()
    private let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var receipt: Receipt?
    private var saveUsernameBlock: StateBlock?
    private var reloadAllSections: Bool = true

    init(service: AccountSettingsService?, settings: AccountSettings?) {
        self.settings = settings
        self.store = AccountSettingsStore(service: service)
        self.receipt = self.store.onStateChange { [weak self] (old, new) in
            DispatchQueue.main.async {
                if old.suggestUsernamesState != new.suggestUsernamesState {
                    self?.suggestionsListener?(new.suggestUsernamesState, new.suggestions, self?.reloadAllSections ?? true)
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
        selectedUsername = username
        suggestUsernames(for: username)
    }

    func suggestUsernames(for username: String, reloadingAllSections: Bool = true) {
        if username.isEmpty {
            return
        }
        reloadAllSections = reloadingAllSections
        store.onDispatch(AccountSettingsAction.suggestUsernames(for: username))
    }

    func save(saveUsernameBlock: @escaping StateBlock) {
        self.saveUsernameBlock = saveUsernameBlock
        store.onDispatch(AccountSettingsAction.saveUsername(username: selectedUsername))
    }

    func headerDescription() -> NSAttributedString {
        let text = String(format: Constants.paragraph, username, Constants.highlight)
        let font = WPStyleGuide.fontForTextStyle(.footnote)
        let bold = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)

        let attributed = NSMutableAttributedString(string: text, attributes: [.font: font])
        attributed.applyStylesToMatchesWithPattern("\\b\(username)", styles: [.font: bold])
        attributed.addAttributes([.underlineStyle: NSNumber(value: 1), .font: bold],
                                 range: (text as NSString).range(of: Constants.highlight))
        return attributed
    }
}

extension ChangeUsernameViewModel: SignupUsernameViewControllerDelegate {
    func usernameSelected(_ username: String) {
        selectedUsername = username
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

    enum Constants {
        static let highlight = NSLocalizedString("You will not be able to change your username back.", comment: "Paragraph text that needs to be highlighted")
        static let paragraph = NSLocalizedString("You are about to change your username, which is currently %@. %@", comment: "Paragraph displayed in the tableview header. The placholders are for the current username, highlight text and the current display name.")

        enum Suggestions {
            static let loading = NSLocalizedString("Loading usernames", comment: "Shown while the app waits for the username suggestions web service to return during the site creation process.")
        }

        enum Error {
            static let saveUsername = NSLocalizedString("There was an error saving the username", comment: "Text displayed when there is a failure saving the username.")
        }
    }
}
