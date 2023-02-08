import WordPressFlux

enum JetpackRemoteInstallEvent {
    // User initiated the Jetpack installation process.
    case start

    // Jetpack plugin installation succeeded.
    case completed

    // Jetpack plugin installation failed.
    case failed(description: String, siteURLString: String)

    // User retried the Jetpack installation process.
    case retry

    // User initiated the Jetpack connection authorization.
    case connect

    // User initiated a login to authorize the Jetpack connection.
    case login
}

class JetpackRemoteInstallViewModel {
    typealias JetpackRemoteInstallOnChangeState = (JetpackRemoteInstallState) -> Void

    var onChangeState: JetpackRemoteInstallOnChangeState?
    private let store = StoreContainer.shared.jetpackInstall
    private var storeReceipt: Receipt?

    private(set) var state: JetpackRemoteInstallState = .install {
        didSet {
            onChangeState?(state)
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

        track(isRetry ? .retry : .start)
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
        }
    }
}
