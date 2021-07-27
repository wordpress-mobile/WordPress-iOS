import UIKit

class JetpackLoginErrorViewController: UIViewController {
    private let viewModel: JetpackErrorViewModel

    // IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!

    init(viewModel: JetpackErrorViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.isPad() ? .all : .portrait
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureImageView()
        configureTitleLabel()
        configureDescriptionLabel()
        configurePrimaryButton()
        configureSecondaryButton()
    }

}

// MARK: - View Configuration
extension JetpackLoginErrorViewController {
    private func configureImageView() {
        guard let image = viewModel.image else {
            imageView.isHidden = true
            imageView.image = nil

            return
        }

        imageView.image = image
    }

    private func configureTitleLabel() {
        guard let title = viewModel.title else {
            return
        }

        titleLabel.isHidden = false
        titleLabel.text = title
    }

    private func configureDescriptionLabel() {
        descriptionLabel.font = Self.descriptionFont
        descriptionLabel.textColor = Self.descriptionTextColor
        descriptionLabel.adjustsFontForContentSizeCategory = true

        guard let attributedString = viewModel.description.attributedStringValue else {
            descriptionLabel.text = viewModel.description.stringValue
            return
        }

        descriptionLabel.attributedText = attributedString
    }

    private func configurePrimaryButton() {
        guard let title = viewModel.primaryButtonTitle else {
            primaryButton.isHidden = true
            return
        }

        primaryButton.setTitle(title, for: .normal)
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.viewModel.didTapPrimaryButton(in: self)
        }
    }

    private func configureSecondaryButton() {
        guard let title = viewModel.secondaryButtonTitle else {
            secondaryButton.isHidden = true
            return
        }

        secondaryButton.setTitle(title, for: .normal)
        secondaryButton.on(.touchUpInside) { [weak self] _ in
            self?.viewModel.didTapSecondaryButton(in: self)
        }
    }
}

// MARK: - Styles
extension JetpackLoginErrorViewController {
    static let descriptionFont: UIFont = WPStyleGuide.fontForTextStyle(.body)
    static let descriptionTextColor: UIColor = .text
}
