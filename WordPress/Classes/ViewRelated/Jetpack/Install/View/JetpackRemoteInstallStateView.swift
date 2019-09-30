import WordPressAuthenticator

protocol JetpackRemoteInstallStateViewDelegate: class {
    func mainButtonDidTouch()
    func customerSupportButtonDidTouch()
}

class JetpackRemoteInstallStateView: UIViewController {
    weak var delegate: JetpackRemoteInstallStateViewDelegate?

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var mainButton: NUXButton!
    @IBOutlet private var supportButton: UIButton!
    @IBOutlet private var activityIndicatorContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func toggleHidingImageView(for collection: UITraitCollection) {
        imageView.isHidden = collection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
    }

    func setupView(for state: JetpackRemoteInstallState) {
        imageView.image = state.image

        titleLabel.text = state.title
        descriptionLabel.text = state.message

        mainButton.isHidden = state == .installing
        mainButton.setTitle(state.buttonTitle, for: .normal)

        activityIndicatorContainer.isHidden = state != .installing

        switch state {
        case .failure:
            supportButton.isHidden = false
        default:
            supportButton.isHidden = true
        }
    }
}

private extension JetpackRemoteInstallStateView {
    func setupUI() {
        view.backgroundColor = .neutral(.shade5)

        titleLabel.font = WPStyleGuide.fontForTextStyle(.title2)
        titleLabel.textColor = .neutral(.shade40)

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = .neutral(.shade70)

        mainButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)

        supportButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .medium)
        supportButton.setTitleColor(.primary, for: .normal)
        supportButton.setTitle(NSLocalizedString("Contact Support", comment: "Contact Support button title"),
                               for: .normal)
    }

    @IBAction func mainButtonAction(_ sender: NUXButton) {
        delegate?.mainButtonDidTouch()
    }

    @IBAction func customSupportButtonAction(_ sender: UIButton) {
        delegate?.customerSupportButtonDidTouch()
    }
}
