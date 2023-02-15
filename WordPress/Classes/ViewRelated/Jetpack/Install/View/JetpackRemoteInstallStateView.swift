import WordPressAuthenticator

protocol JetpackRemoteInstallStateViewDelegate: AnyObject {
    func mainButtonDidTouch()
    func customerSupportButtonDidTouch()
}

struct JetpackRemoteInstallStateViewData {
    let image: UIImage?
    let titleText: String
    let descriptionText: String
    let buttonTitleText: String

    let hidesMainButton: Bool
    let hidesLoadingIndicator: Bool
    let hidesSupportButton: Bool
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

    func configure(with viewData: JetpackRemoteInstallStateViewData) {
        imageView.image = viewData.image

        titleLabel.text = viewData.titleText
        descriptionLabel.text = viewData.descriptionText

        mainButton.isHidden = viewData.hidesMainButton
        mainButton.setTitle(viewData.buttonTitleText, for: .normal)

        activityIndicatorContainer.isHidden = viewData.hidesLoadingIndicator

        supportButton.isHidden = viewData.hidesSupportButton
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
