import WordPressAuthenticator


protocol JetpackRemoteInstallDelegate: class {
    func jetpackRemoteInstallCompleted()
    func jetpackRemoteInstallCanceled()
}

class JetpackRemoteInstallViewController: UIViewController {
    private weak var delegate: JetpackRemoteInstallDelegate?
    private var promptType: JetpackLoginPromptType
    private var blog: Blog
    private let viewModel: JetpackRemoteInstallViewModel

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var mainButton: NUXButton!
    @IBOutlet private var supportButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!


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

        setupNavigationBar()
        setupUI()
        setupViewModel()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        hideImageView(with: newCollection)
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

        hideImageView(with: traitCollection)

        titleLabel.font = WPStyleGuide.fontForTextStyle(.title2)
        titleLabel.textColor = WPStyleGuide.greyDarken10()

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = WPStyleGuide.darkGrey()

        mainButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)

        supportButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .medium)
        supportButton.setTitleColor(WPStyleGuide.wordPressBlue(), for: .normal)
        supportButton.setTitle(NSLocalizedString("Contact Support", comment: "Contact Support button title"),
                               for: .normal)
    }

    func setupViewModel() {
        viewModel.onChangeState = { [weak self] state in
            self?.setupView(for: state)
        }
        viewModel.viewReady()
    }

    func setupView(for state: JetpackRemoteInstallViewState) {
        imageView.image = state.image

        titleLabel.text = state.title
        descriptionLabel.text = state.message

        mainButton.isHidden = state == .installing
        mainButton.setTitle(state.buttonTitle, for: .normal)

        activityIndicator.animate(state == .installing)

        switch state {
        case .failure(let error):
            supportButton.isHidden = false
            if error.isBlockingError {
                openInstallJetpackURL()
            }
        default:
            supportButton.isHidden = true
        }
    }

    func hideImageView(with collection: UITraitCollection) {
        imageView.isHidden = collection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
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

extension JetpackRemoteInstallViewController: JetpackConnectionWebDelegate {
    func jetpackConnectionCanceled() {
        delegate?.jetpackRemoteInstallCanceled()
    }

    func jetpackConnectionCompleted() {
        delegate?.jetpackRemoteInstallCompleted()
    }
}

private extension UIActivityIndicatorView {
    func animate(_ animate: Bool) {
        if animate {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
}

private extension JetpackRemoteInstallViewController {
    @IBAction func stateChange(_ sender: UISegmentedControl) {
        viewModel.testState(sender.selectedSegmentIndex)
    }
}
