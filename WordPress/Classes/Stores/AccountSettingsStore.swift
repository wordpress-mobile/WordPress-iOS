import WordPressFlux

enum AccountSettingsState: Equatable {
    case stationary
    case loading
    case success
    case failure(String?)

    static func == (lhs: AccountSettingsState, rhs: AccountSettingsState) -> Bool {
        switch (lhs, rhs) {
        case (.stationary, .stationary),
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
    case validate(username: String)
    case saveUsername(username: String)
}

struct AccountSettingsStoreState {
    fileprivate(set) var usernameValidationState: AccountSettingsState = .stationary
    fileprivate(set) var usernameSaveState: AccountSettingsState = .stationary
}

class AccountSettingsStore: StatefulStore<AccountSettingsStoreState> {
    var validationState: AccountSettingsState {
        return state.usernameValidationState
    }

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
        case .validate(let username):
            validate(username: username)
        case .saveUsername(let username):
            saveUsername(username: username)
        }
    }

    func validationSucceeded() -> Bool {
        return state.usernameValidationState.succeeded
    }
}

private extension AccountSettingsStore {
    func validate(username: String) {
        if state.usernameValidationState == .loading {
            return
        }

        state.usernameValidationState = .loading

        service?.validateUsername(to: username, success: { [weak self] in
            DDLogInfo("Validation of \(username) username finished successfully")

            DispatchQueue.main.async {
                self?.transaction { state in
                    state.usernameValidationState = .success
                }
            }
        }) { [weak self] error in
            DDLogInfo("Validation username failed: \(error.localizedDescription)")

            DispatchQueue.main.async {
                self?.transaction { state in
                    state.usernameValidationState = .failure(error.localizedDescription)
                }
            }
        }
    }

    func saveUsername(username: String) {
        if state.usernameValidationState == .loading ||
            state.usernameSaveState == .loading {
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
}
