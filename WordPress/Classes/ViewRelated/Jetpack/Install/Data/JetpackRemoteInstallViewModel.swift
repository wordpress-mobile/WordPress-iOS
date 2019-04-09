import WordPressFlux

class JetpackRemoteInstallViewModel {
    typealias JetpackRemoteInstallOnChangeState = (JetpackRemoteInstallViewState) -> Void

    var onChangeState: JetpackRemoteInstallOnChangeState?
    private let store: JetpackInstallStore
    private var storeReceipt: Receipt?

    private(set) var state: JetpackRemoteInstallViewState = .install {
        didSet {
            onChangeState?(state)
        }
    }

    init() {
        self.store = JetpackInstallStore()
    }

    func viewReady() {
        state = .install

        storeReceipt = store.onStateChange { [weak self] (_, state) in
            switch state.current {
            case .loading:
                self?.state = .installing
            case .success:
                self?.state = .success
            case .failure(let error):
                self?.state = .failure(error)
            default:
                break
            }
        }
    }

    func installJetpack(with url: String, username: String, password: String) {
        store.onDispatch(JetpackInstallAction.install(url: url, username: username, password: password))
    }
}
