import UIKit

class JetpackScanStatusCell: UITableViewCell, NibReusable {
    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var primaryButton: FancyButton!
    @IBOutlet weak var secondaryButton: FancyButton!
    @IBOutlet weak var warningButton: MultilineButton!
    @IBOutlet weak var progressView: UIProgressView!

    private var model: JetpackScanStatusViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()

        primaryButton.isHidden = true
        secondaryButton.isHidden = true
        configureProgressView()
    }

    public func configure(with model: JetpackScanStatusViewModel) {
        self.model = model

        iconImageView.image = UIImage(named: model.imageName)
        titleLabel.text = model.title
        descriptionLabel.text = model.description

        configurePrimaryButton(model)
        configureSecondaryButton(model)
        configureWarningButton(model)
        configureProgressView(model)
    }

    private func configurePrimaryButton(_ model: JetpackScanStatusViewModel) {
        guard let primaryTitle = model.primaryButtonTitle else {
            primaryButton.isHidden = true
            return
        }

        primaryButton.setTitle(primaryTitle, for: .normal)
        primaryButton.isEnabled = model.primaryButtonEnabled
        primaryButton.isHidden = false
    }

    private func configureSecondaryButton(_ model: JetpackScanStatusViewModel) {
        guard let secondaryTitle = model.secondaryButtonTitle else {
            secondaryButton.isHidden = true
            return
        }

        secondaryButton.setTitle(secondaryTitle, for: .normal)
        secondaryButton.isHidden = false
    }

    private func configureWarningButton(_ model: JetpackScanStatusViewModel) {
        guard let warningButtonTitle = model.warningButtonTitle else {
            warningButton.isHidden = true
            return
        }

        let attributedTitle = WPStyleGuide.Jetpack.highlightString(warningButtonTitle.substring,
                                                                   inString: warningButtonTitle.string)

        warningButton.setAttributedTitle(attributedTitle, for: .normal)
        warningButton.setImage(.gridicon(.plusSmall), for: .normal)
        warningButton.setTitleColor(.text, for: .normal)
        warningButton.titleLabel?.numberOfLines = 0
        warningButton.titleLabel?.lineBreakMode = .byWordWrapping

        warningButton.isHidden = false
    }

    private func configureProgressView(_ model: JetpackScanStatusViewModel) {
        guard let progress = model.progress else {
            progressView.isHidden = true
            return
        }

        progressView.isHidden = false
        progressView.setProgress(progress, animated: true)
    }

    // MARK: - IBAction's
    @IBAction func primaryButtonTapped(_ sender: Any) {
        guard let viewModel = model else {
            return
        }

        viewModel.primaryButtonTapped(sender)
    }

    @IBAction func secondaryButtonTapped(_ sender: Any) {
        guard let viewModel = model else {
            return
        }

        viewModel.secondaryButtonTapped(sender)
    }

    @IBAction func warningButtonTapped(_ sender: Any) {
        guard let viewModel = model else {
            return
        }

        viewModel.warningButtonTapped(sender)
    }

    // MARK: - Private: View Configuration
    private func configureProgressView() {
        progressView.isHidden = true

        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true

        let color = UIColor.muriel(color: .jetpackGreen, .shade50)
        progressView.tintColor = color
    }
}
