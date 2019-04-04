import WordPressAuthenticator

protocol JetpackRemoteInstallViewDelegate: class {
    func mainButtonDidTouch()
    func customerSupportButtonDidTouch()
}

class JetpackRemoteInstallView: UIViewController {
    weak var delegate: JetpackRemoteInstallViewDelegate?

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var mainButton: NUXButton!
    @IBOutlet private var supportButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func toggleHidingImageView(for collection: UITraitCollection) {
        imageView.isHidden = collection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
    }

    func setupView(for state: JetpackRemoteInstallViewState) {
        imageView.image = state.image

        titleLabel.text = state.title
        descriptionLabel.text = state.message

        mainButton.isHidden = state == .installing
        mainButton.setTitle(state.buttonTitle, for: .normal)

        activityIndicator.toggleAnimating(state == .installing)

        switch state {
        case .failure:
            supportButton.isHidden = false
        default:
            supportButton.isHidden = true
        }
    }
}

private extension JetpackRemoteInstallView {
    func setupUI() {
        view.backgroundColor = WPStyleGuide.itsEverywhereGrey()

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

    @IBAction func mainButtonAction(_ sender: NUXButton) {
        delegate?.mainButtonDidTouch()
    }

    @IBAction func customSupportButtonAction(_ sender: UIButton) {
        delegate?.customerSupportButtonDidTouch()
    }
}

// MARK: - UIActivityIndicatorView extension

private extension UIActivityIndicatorView {
    func toggleAnimating(_ animate: Bool) {
        if animate {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
}
