import WordPressAuthenticator


protocol JetpackRemoteInstallDelegate: class {
    func jetpackRemoteInstallCompleted()
    func jetpackRemoteInstallCanceled()
    func jetpackRemoteInstallWebviewFallback()
}

class JetpackRemoteInstallViewController: UIViewController {
    private weak var delegate: JetpackRemoteInstallDelegate?
    private var promptType: JetpackLoginPromptType
    private var blog: Blog
    private let jetpackView = JetpackRemoteInstallView()
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

    override func loadView() {
        view = UIView()
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
        view.backgroundColor = WPStyleGuide.greyLighten30()

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

            if case let .failure(error) = state {
                if error.isBlockingError {
                    self?.delegate?.jetpackRemoteInstallWebviewFallback()
                }
            }
        }
    }

    func openInstallJetpackURL() {
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

extension JetpackRemoteInstallViewController: JetpackRemoteInstallViewDelegate {
    func mainButtonDidTouch() {
        guard let url = blog.url,
            let username = blog.username,
            let password = blog.password else {
            return
        }

        switch viewModel.state {
        case .install, .failure:
            viewModel.installJetpack(with: url, username: username, password: password)
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
