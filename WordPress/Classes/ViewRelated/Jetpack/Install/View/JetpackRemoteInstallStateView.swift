import WordPressAuthenticator

protocol JetpackRemoteInstallStateViewDelegate: AnyObject {
    func mainButtonDidTouch()
    func customerSupportButtonDidTouch()
}

protocol JetpackRemoteInstallStateViewModel: AnyObject {
    var image: UIImage? { get }
    var titleText: String { get }
    var descriptionText: String { get }
    var buttonTitleText: String { get }

    var hidesMainButton: Bool { get }
    var hidesLoadingIndicator: Bool { get }
    var hidesSupportButton: Bool { get }
}

class JetpackRemoteInstallStateView: UIViewController {
    weak var delegate: JetpackRemoteInstallStateViewDelegate?
    weak var model: JetpackRemoteInstallStateViewModel?

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

    func setupView() {
        guard let model else {
            return
        }

        imageView.image = model.image

        titleLabel.text = model.titleText
        descriptionLabel.text = model.descriptionText

        mainButton.isHidden = model.hidesMainButton
        mainButton.setTitle(model.buttonTitleText, for: .normal)

        activityIndicatorContainer.isHidden = model.hidesLoadingIndicator

        supportButton.isHidden = model.hidesSupportButton
    }
}

private extension JetpackRemoteInstallStateView {
    func setupUI() {
        WPStyleGuide.configureColors(view: view, tableView: nil)

        titleLabel.font = WPStyleGuide.fontForTextStyle(.title2)
        titleLabel.textColor = .text

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = .textSubtle

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
