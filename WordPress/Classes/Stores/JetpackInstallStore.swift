import WordPressFlux

enum JetpackInstallAction: Action {
    case install(url: String, username: String, password: String)
}

struct JetpackInstallStoreState {
    enum State {
        case install
        case loading
        case failure(JetpackInstallError)
        case success
    }

    var current: State = .install
}

class JetpackInstallStore: StatefulStore<JetpackInstallStoreState> {
    private let service = JetpackService()

    init() {
        super.init(initialState: JetpackInstallStoreState())
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? JetpackInstallAction else {
            return
        }

        switch action {
        case .install(let url, let username, let password):
            startInstallingJetpack(with: url, username: username, password: password)
        }
    }
}

private extension JetpackInstallStore {
    func startInstallingJetpack(with url: String, username: String, password: String) {
        if case .loading = state.current {
            return
        }

        state.current = .loading
        service.installJetpack(url: url, username: username, password: password) { [weak self] (success, error) in
            self?.transaction({ (state) in
                if success {
                    state.current = .success
                } else {
                    state.current = .failure(error ?? .unknown)
                }
            })
        }
    }
}
