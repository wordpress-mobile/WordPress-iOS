import UIKit

class JetpackScanStatusCell: UITableViewCell, NibReusable {
    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var primaryButton: FancyButton!
    @IBOutlet weak var secondaryButton: FancyButton!
    @IBOutlet weak var progressView: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()

        primaryButton.isHidden = true
        secondaryButton.isHidden = true
        configureProgressView()
    }

    public func configure(with model: JetpackScanStatusViewModel) {
        iconImageView.image = UIImage(named: model.imageName)
        titleLabel.text = model.title
        descriptionLabel.text = model.description

        configurePrimaryButton(model)
        configureSecondaryButton(model)
        configureProgressView(model)
    }

    private func configurePrimaryButton(_ model: JetpackScanStatusViewModel) {
        guard let primaryTitle = model.primaryButtonTitle else {
            primaryButton.isHidden = true
            return
        }

        primaryButton.setTitle(primaryTitle, for: .normal)
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
    }

    @IBAction func secondaryButtonTapped(_ sender: Any) {
    }

    // MARK: - Private: View Configuration
    private func configureProgressView() {
        progressView.isHidden = true

        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        // TODO: Replace hex with styleguide color
        progressView.tintColor = .init(fromHex: 0x069e08)
    }
}
