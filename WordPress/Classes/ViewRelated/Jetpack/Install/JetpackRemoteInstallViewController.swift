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

    init(blog: Blog,
         delegate: JetpackRemoteInstallDelegate?,
         viewModel: JetpackRemoteInstallViewModel = SelfHostedJetpackRemoteInstallViewModel()) {
        self.blog = blog
        self.delegate = delegate
        self.viewModel = viewModel
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
        viewModel.onChangeState = { [weak self] state, viewData in
            guard let self else {
                return
            }

            DispatchQueue.main.async {
                self.jetpackView.configure(with: viewData)
            }

            switch state {
            case .install:
                self.viewModel.track(.initial)
            case .installing:
                self.viewModel.track(.loading)
            case .success:
                self.viewModel.track(.completed)

                // Hide the Cancel button if the flow skips the Jetpack connection.
                if !self.viewModel.shouldConnectToJetpack {
                    self.navigationItem.setLeftBarButton(nil, animated: false)
                }

            case .failure(let error):
                let blogURLString = self.blog.url ?? "unknown"
                self.viewModel.track(.failed(description: error.description, siteURLString: blogURLString))

                let title = error.title ?? "no error message"
                let type = error.type.rawValue
                let code = error.code
                DDLogError("Jetpack Remote Install error for site \(blogURLString) – \(title) (\(code): \(type))")

                if error.isBlockingError {
                    DDLogInfo("Jetpack Remote Install error - Blocking error")
                    self.delegate?.jetpackRemoteInstallWebviewFallback()
                }
            }
        }
    }

    func openInstallJetpackURL() {
        viewModel.track(AccountHelper.isLoggedIn ? .connect : .login)

        let controller = JetpackConnectionWebViewController(blog: blog)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    /// Cancels the flow.
    @objc func cancel() {
        viewModel.track(.cancel)
        viewModel.cancelTapped()
        delegate?.jetpackRemoteInstallCanceled()
    }

    /// Completes the Jetpack installation flow.
    func complete() {
        if let siteID = blog.dotComID?.stringValue {
            RecentJetpackInstallReceipt.shared.store(siteID)
        }
        delegate?.jetpackRemoteInstallCompleted()
    }
}

// MARK: - Jetpack Connection Web Delegate

extension JetpackRemoteInstallViewController: JetpackConnectionWebDelegate {
    func jetpackConnectionCanceled() {
        cancel()
    }

    func jetpackConnectionCompleted() {
        complete()
    }
}

// MARK: - Jetpack View delegate

extension JetpackRemoteInstallViewController: JetpackRemoteInstallStateViewDelegate {
    func mainButtonDidTouch() {
        switch viewModel.state {
        case .install:
            viewModel.track(.start)
            viewModel.installJetpack(for: blog, isRetry: false)
        case .failure:
            viewModel.track(.retry)
            viewModel.installJetpack(for: blog, isRetry: true)
        case .success:
            viewModel.track(.completePrimaryButtonTapped)
            guard viewModel.shouldConnectToJetpack else {
                complete()
                return
            }
            openInstallJetpackURL()
        default:
            break
        }
    }

    func customerSupportButtonDidTouch() {
        let supportViewController = SupportTableViewController()
        supportViewController.sourceTag = viewModel.supportSourceTag
        navigationController?.pushViewController(supportViewController, animated: true)
    }
}

// MARK: - Error Helpers

extension JetpackInstallError {
    /// When the error is unknown, return the error title (if it exists) to get a more descriptive reason.
    var description: String {
        if let title,
           type == .unknown {
            return title
        }
        return type.rawValue
    }
}
