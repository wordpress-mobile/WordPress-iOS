import WordPressAuthenticator

protocol JetpackRemoteInstallDelegate: class {
    func jetpackRemoteInstallCompleted()
    func jetpackRemoteInstallCanceled()
    func jetpackRemoteInstallWebviewFallback()
}

class JetpackRemoteInstallViewController: UIViewController {
    private typealias JetpackInstallBlock = (String, String, String, WPAnalyticsStat) -> Void

    private weak var delegate: JetpackRemoteInstallDelegate?
    private var promptType: JetpackLoginPromptType
    private var blog: Blog
    private let jetpackView = JetpackRemoteInstallStateView()
    private let viewModel: JetpackRemoteInstallViewModel

    init(blog: Blog, delegate: JetpackRemoteInstallDelegate?, promptType: JetpackLoginPromptType) {
        self.blog = blog
        self.delegate = delegate
        self.promptType = promptType
        self.viewModel = JetpackRemoteInstallViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewModel()
        setupNavigationBar()
        setupUI()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        jetpackView.toggleHidingImageView(for: newCollection)
    }
}

// MARK: - Private functions

private extension JetpackRemoteInstallViewController {
    func setupNavigationBar() {
        title = NSLocalizedString("Jetpack", comment: "Title for the Jetpack Installation")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancel))
    }

    func setupUI() {
        view.backgroundColor = .neutral(.shade5)

        jetpackView.delegate = self
        add(jetpackView)
        jetpackView.view.frame = view.bounds

        jetpackView.toggleHidingImageView(for: traitCollection)

        viewModel.viewReady()
    }

    func setupViewModel() {
        viewModel.onChangeState = { [weak self] state in
            DispatchQueue.main.async {
                self?.jetpackView.setupView(for: state)
            }

            switch state {
            case .success:
                WPAnalytics.track(.installJetpackRemoteCompleted)
            case .failure(let error):
                WPAnalytics.track(.installJetpackRemoteFailed,
                                  withProperties: ["error": error.type.rawValue,
                                                   "site_url": self?.blog.url ?? "unknown"])
                let url = self?.blog.url ?? "unknown"
                let title = error.title ?? "no error message"
                let type = error.type.rawValue
                let code = error.code
                DDLogError("Jetpack Remote Install error for site \(url) – \(title) (\(code): \(type))")

                if error.isBlockingError {
                    DDLogInfo("Jetpack Remote Install error - Blocking error")
                    self?.delegate?.jetpackRemoteInstallWebviewFallback()
                }
            default:
                break
            }
        }
    }

    func openInstallJetpackURL() {
        let event: WPAnalyticsStat = AccountHelper.isLoggedIn ? .installJetpackRemoteConnect : .installJetpackRemoteLogin
        WPAnalytics.track(event)

        let controller = JetpackConnectionWebViewController(blog: blog)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    func installJetpack(with url: String, username: String, password: String, event: WPAnalyticsStat) {
        WPAnalytics.track(event)
        viewModel.installJetpack(with: url, username: username, password: password)
    }

    @objc func cancel() {
        delegate?.jetpackRemoteInstallCanceled()
    }
}

// MARK: - Jetpack Connection Web Delegate

extension JetpackRemoteInstallViewController: JetpackConnectionWebDelegate {
    func jetpackConnectionCanceled() {
        delegate?.jetpackRemoteInstallCanceled()
    }

    func jetpackConnectionCompleted() {
        delegate?.jetpackRemoteInstallCompleted()
    }
}

// MARK: - Jetpack View delegate

extension JetpackRemoteInstallViewController: JetpackRemoteInstallStateViewDelegate {
    func mainButtonDidTouch() {
        guard let url = blog.url,
            let username = blog.username,
            let password = blog.password else {
            return
        }

        switch viewModel.state {
        case .install:
            installJetpack(with: url, username: username, password: password, event: .installJetpackRemoteStart)
        case .failure:
            installJetpack(with: url, username: username, password: password, event: .installJetpackRemoteRetry)
        case .success:
            openInstallJetpackURL()
        default:
            break
        }
    }

    func customerSupportButtonDidTouch() {
        navigationController?.pushViewController(SupportTableViewController(), animated: true)
    }
}
