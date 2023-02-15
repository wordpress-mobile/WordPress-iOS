import WordPressFlux
import WordPressAuthenticator

class SelfHostedJetpackRemoteInstallViewModel: JetpackRemoteInstallViewModel {
    var onChangeState: ((JetpackRemoteInstallState, JetpackRemoteInstallStateViewModel) -> Void)?
    private let store = StoreContainer.shared.jetpackInstall
    private var storeReceipt: Receipt?

    /// Always proceed to the Jetpack Connection flow after successfully installing Jetpack.
    let shouldConnectToJetpack = true

    let supportSourceTag: WordPressSupportSourceTag? = nil

    private(set) var state: JetpackRemoteInstallState = .install {
        didSet {
            onChangeState?(state, .init(state: state))
        }
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

    func installJetpack(for blog: Blog, isRetry: Bool = false) {
        guard let url = blog.url,
              let username = blog.username,
              let password = blog.password else {
            return
        }

        store.onDispatch(JetpackInstallAction.install(url: url, username: username, password: password))
    }

    func track(_ event: JetpackRemoteInstallEvent) {
        switch event {
        case .start:
            WPAnalytics.track(.installJetpackRemoteStart)
        case .completed:
            WPAnalytics.track(.installJetpackRemoteCompleted)
        case .failed(let description, let siteURLString):
            WPAnalytics.track(.installJetpackRemoteFailed,
                              withProperties: ["error_type": description, "site_url": siteURLString])
        case .retry:
            WPAnalytics.track(.installJetpackRemoteRetry)
        case .connect:
            WPAnalytics.track(.installJetpackRemoteConnect)
        case .login:
            WPAnalytics.track(.installJetpackRemoteLogin)
        default:
            break
        }
    }

    func cancelTapped() {
         // No op
    }
}
