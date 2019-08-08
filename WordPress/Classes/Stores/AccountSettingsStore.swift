import WordPressFlux

enum AccountSettingsState: Equatable {
    case idle
    case loading
    case success
    case failure(String?)

    static func == (lhs: AccountSettingsState, rhs: AccountSettingsState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.success, .success):
            return true
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }

    var succeeded: Bool {
        return self == .success
    }

    var failureMessage: String? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}

enum AccountSettingsAction: Action {
    case saveUsername(username: String)
    case suggestUsernames(for: String)
}

struct AccountSettingsStoreState {
    fileprivate(set) var usernameSaveState: AccountSettingsState = .idle
    fileprivate(set) var suggestUsernamesState: AccountSettingsState = .idle

    fileprivate(set) var suggestions: [String] = []
}

class AccountSettingsStore: StatefulStore<AccountSettingsStoreState> {
    private weak var service: AccountSettingsService?

    init(service: AccountSettingsService?) {
        self.service = service

        super.init(initialState: AccountSettingsStoreState())
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? AccountSettingsAction else {
            return
        }

        switch action {
        case .saveUsername(let username):
            saveUsername(username: username)
        case .suggestUsernames(let username):
            suggestUsernames(for: username)
        }
    }

    func isLoading() -> Bool {
        return state.usernameSaveState == .loading ||
            state.suggestUsernamesState == .loading
    }
}

private extension AccountSettingsStore {
    func saveUsername(username: String) {
        if isLoading() {
            return
        }

        state.usernameSaveState = .loading

        service?.changeUsername(to: username, success: { [weak self] in
            DDLogInfo("Saving \(username) username succeeded")

            DispatchQueue.main.async {
                self?.transaction { state in
                    state.usernameSaveState = .success
                }
            }
        }, failure: { [weak self] in
            DDLogInfo("Saving \(username) username failed")

            DispatchQueue.main.async {
                self?.transaction { state in
                    state.usernameSaveState = .failure(nil)
                }
            }
        })
    }

    func suggestUsernames(for username: String) {
        if isLoading() {
            return
        }

        state.suggestUsernamesState = .loading

        service?.suggestUsernames(base: username) { [weak self] suggestions in
            DDLogInfo("Usernames suggestion finished finding \(suggestions.count) usernames")

            DispatchQueue.main.async {
                self?.transaction { state in
                    state.suggestUsernamesState = .success
                    state.suggestions = suggestions
                }
            }
        }
    }
}
