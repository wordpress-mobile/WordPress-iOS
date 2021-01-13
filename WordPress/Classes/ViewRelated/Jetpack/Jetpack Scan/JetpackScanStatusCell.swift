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

        if let primaryTitle = model.primaryButtonTitle {
            primaryButton.setTitle(primaryTitle, for: .normal)
            primaryButton.isHidden = false
        } else {
            primaryButton.isHidden = true
        }

        if let secondaryTitle = model.secondaryButtonTitle {
            secondaryButton.setTitle(secondaryTitle, for: .normal)
            secondaryButton.isHidden = false
        } else {
            secondaryButton.isHidden = true
        }

        if let progress = model.progress {
            progressView.isHidden = false
            progressView.progress = progress
        } else {
            progressView.isHidden = true
        }
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
