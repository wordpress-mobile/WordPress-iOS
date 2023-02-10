import WordPressAuthenticator

protocol JetpackRemoteInstallDelegate: AnyObject {
    func jetpackRemoteInstallCompleted()
    func jetpackRemoteInstallCanceled()
    func jetpackRemoteInstallWebviewFallback()
}

class JetpackRemoteInstallViewController: UIViewController {
    private weak var delegate: JetpackRemoteInstallDelegate?
    private var blog: Blog
    private let jetpackView = JetpackRemoteInstallStateView()
    private let viewModel: JetpackRemoteInstallViewModel

    init(blog: Blog, delegate: JetpackRemoteInstallDelegate?) {
        self.blog = blog
        self.delegate = delegate
        self.viewModel = SelfHostedJetpackRemoteInstallViewModel()
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
        jetpackView.model = viewModel
        add(jetpackView)
        jetpackView.view.frame = view.bounds

        jetpackView.toggleHidingImageView(for: traitCollection)

        viewModel.viewReady()
    }

    func setupViewModel() {
        viewModel.onChangeState = { [weak self] state in
            DispatchQueue.main.async {
                self?.jetpackView.setupView()
            }

            switch state {
            case .success:
                self?.viewModel.track(.completed)
            case .failure(let error):
                let blogURLString = self?.blog.url ?? "unknown"
                self?.viewModel.track(.failed(description: error.type.rawValue, siteURLString: blogURLString))

                let title = error.title ?? "no error message"
                let type = error.type.rawValue
                let code = error.code
                DDLogError("Jetpack Remote Install error for site \(blogURLString) – \(title) (\(code): \(type))")

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
        viewModel.track(AccountHelper.isLoggedIn ? .connect : .login)

        let controller = JetpackConnectionWebViewController(blog: blog)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
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
        switch viewModel.state {
        case .install:
            viewModel.installJetpack(for: blog, isRetry: false)
        case .failure:
            viewModel.installJetpack(for: blog, isRetry: true)
        case .success:
            guard viewModel.shouldConnectToJetpack else {
                delegate?.jetpackRemoteInstallCompleted()
                return
            }
            openInstallJetpackURL()
        default:
            break
        }
    }

    func customerSupportButtonDidTouch() {
        navigationController?.pushViewController(SupportTableViewController(), animated: true)
    }
}
