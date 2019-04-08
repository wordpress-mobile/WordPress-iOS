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
    init() {
        super.init(initialState: JetpackInstallStoreState())
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? JetpackInstallAction else {
            return
        }

        switch action {
//        case .install(let url, let username, let password):
        case .install:
            state.current = .loading
        }
    }
}
