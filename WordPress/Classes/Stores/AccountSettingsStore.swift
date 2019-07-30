import WordPressFlux

enum AccountSettingsState: Equatable {
    case stationary
    case loading
    case success
    case failure(Error?)

    static func == (lhs: AccountSettingsState, rhs: AccountSettingsState) -> Bool {
        switch (lhs, rhs) {
        case (.stationary, .stationary),
             (.loading, .loading),
             (.success, .success):
            return true
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
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
            return error?.localizedDescription
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
        case .saveUsername:
            break
        }
    }

    func validationSucceeded() -> Bool {
        return state.usernameValidationState.succeeded
    }
}

private extension AccountSettingsStore {
    func validate(username: String) {
        service?.validateUsername(to: username, success: { [weak self] in
            self?.usernameValidationSuccess()
        }) { [weak self] error in
            self?.usernameValidationFailure(error)
        }
    }

    func usernameValidationSuccess() {
        DispatchQueue.main.async {
            self.transaction { state in
                state.usernameValidationState = .success
            }
        }
    }

    func usernameValidationFailure(_ error: Error?) {
        DispatchQueue.main.async {
            self.transaction { state in
                state.usernameValidationState = .failure(error)
            }
        }
    }
}
