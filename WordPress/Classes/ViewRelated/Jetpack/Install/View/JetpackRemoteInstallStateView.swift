import CoreUI

import WordPressAuthenticator

protocol JetpackRemoteInstallStateViewDelegate: AnyObject {
    func mainButtonDidTouch()
    func customerSupportButtonDidTouch()
}

struct JetpackRemoteInstallStateViewModel {
    let image: UIImage?
    let titleText: String
    let descriptionText: String
    let buttonTitleText: String

    let hidesLoadingIndicator: Bool
    let hidesSupportButton: Bool
}

class JetpackRemoteInstallStateView: UIViewController {
    weak var delegate: JetpackRemoteInstallStateViewDelegate?

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var mainButton: UIButton!
    @IBOutlet private var supportButton: UIButton!

    private var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = Constants.MainButton.activityIndicatorColor
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func toggleHidingImageView(for collection: UITraitCollection) {
        imageView.isHidden = collection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
    }

    func configure(with viewModel: JetpackRemoteInstallStateViewModel) {
        imageView.image = viewModel.image

        titleLabel.text = viewModel.titleText
        descriptionLabel.text = viewModel.descriptionText

        mainButton.setTitle(viewModel.buttonTitleText, for: .normal)

        toggleLoading(!viewModel.hidesLoadingIndicator)

        supportButton.isHidden = viewModel.hidesSupportButton
        view.layoutIfNeeded()
    }
}

private extension JetpackRemoteInstallStateView {
    func setupUI() {
        WPStyleGuide.configureColors(view: view, tableView: nil)

        titleLabel.font = Constants.Title.font
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Constants.Title.color

        descriptionLabel.font = Constants.Description.font
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.textColor = Constants.Description.color

        configureTitleLabel(for: mainButton, font: Constants.MainButton.font)
        mainButton.setTitleColor(Constants.MainButton.titleColor, for: .normal)
        mainButton.setTitle(String(), for: .disabled)
        mainButton.setBackgroundImage(Constants.MainButton.normalBackground, for: .normal)
        mainButton.setBackgroundImage(Constants.MainButton.loadingBackground, for: .disabled)
        mainButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)

        mainButton.addSubview(activityIndicator)
        mainButton.pinSubviewAtCenter(activityIndicator)

        configureTitleLabel(for: supportButton, font: Constants.SupportButton.font)
        supportButton.setTitleColor(Constants.SupportButton.color, for: .normal)
        supportButton.setTitle(Constants.SupportButton.text, for: .normal)
    }

    // enables multi-line support for the button.
    func configureTitleLabel(for button: UIButton, font: UIFont) {
        guard let label = button.titleLabel else {
            return
        }

        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        button.pinSubviewToAllEdges(label)
    }

    func toggleLoading(_ loading: Bool) {
        mainButton.isEnabled = !loading

        if loading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    @IBAction func mainButtonAction(_ sender: NUXButton) {
        delegate?.mainButtonDidTouch()
    }

    @IBAction func customSupportButtonAction(_ sender: UIButton) {
        delegate?.customerSupportButtonDidTouch()
    }

    // MARK: Constants

    struct Constants {
        struct Title {
            static let font = WPStyleGuide.fontForTextStyle(.title2)
            static let color = UIColor.text
        }

        struct Description {
            static let font = WPStyleGuide.fontForTextStyle(.callout)
            static let color = UIColor.textSubtle
        }

        struct MainButton {
            static let normalBackground = UIImage.renderBackgroundImage(fill: .brand)
            static let loadingBackground = UIImage.renderBackgroundImage(fill: .muriel(color: .jetpackGreen, .shade70))
            static let titleColor = UIColor.white
            static let font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
            static let activityIndicatorColor = UIColor.white
        }

        struct SupportButton {
            static let color = UIColor.brand
            static let font = WPStyleGuide.fontForTextStyle(.body)
            static let text = NSLocalizedString("Contact Support", comment: "Contact Support button title")
        }
    }
}
