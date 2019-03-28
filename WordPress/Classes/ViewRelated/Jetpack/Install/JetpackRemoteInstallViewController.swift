protocol JetpackRemoteInstallDelegate: class {
    func jetpackRemoteInstallCompleted()
    func jetpackRemoteInstallCanceled()
}

class JetpackRemoteInstallViewController: UIViewController {
    private weak var delegate: JetpackRemoteInstallDelegate?
    private var promptType: JetpackLoginPromptType
    private var blog: Blog

    init(blog: Blog, delegate: JetpackRemoteInstallDelegate?, promptType: JetpackLoginPromptType) {
        self.blog = blog
        self.delegate = delegate
        self.promptType = promptType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
    }
}


private extension JetpackRemoteInstallViewController {
    func setupNavigationBar() {
        title = NSLocalizedString("Jetpack", comment: "Title for the Jetpack Installation")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancel))
    }

    func setupUI() {
        view.backgroundColor = WPStyleGuide.itsEverywhereGrey()
    }

    @objc func cancel() {
        delegate?.jetpackRemoteInstallCanceled()
    }
}
