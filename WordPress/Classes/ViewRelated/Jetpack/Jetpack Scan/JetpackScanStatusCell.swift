import UIKit

class JetpackScanStatusCell: UITableViewCell {
    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var defaultButton: FancyButton!
    @IBOutlet weak var secondaryButton: FancyButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.defaultButton.isHidden = true
        self.secondaryButton.isHidden = true
    }

    public func configure(with scan: JetpackScan) {

        switch scan.state {
        case .idle:
            updateForIdleState(scan: scan)
        case .scanning:
            updateForScanningState(scan: scan)
        default:
            updateForIdleState(scan: scan)
        }
    }

    private func updateForIdleState(scan: JetpackScan) {
        guard let threats = scan.threats, threats.count != 0 else {
            self.iconImageView.image = UIImage(named: "jetpack-scan-state-okay")
            self.titleLabel.text = "Don’t worry about a thing"
            self.descriptionLabel.text = "The last Jetpack scan ran a few seconds ago and everything looked great.\nRun a manual scan now or wait for Jetpack to scan your site later today."
            self.defaultButton.isHidden = true
            self.secondaryButton.isHidden = false
            self.secondaryButton.setTitle("Scan Now", for: .normal)
            return
        }

        self.iconImageView.image = UIImage(named: "jetpack-scan-state-error")
        self.titleLabel.text = "Your site may be at risk"
        self.descriptionLabel.text = "Jetpack Scan found \(threats.count) potential threats on Jetpack Test - Personal. Please review each threat and take action."

        let hasFixableThreats = threats.map { $0.fixable != nil }.count > 0

        if hasFixableThreats {
            self.defaultButton.setTitle("Fix All", for: .normal)
            self.secondaryButton.setTitle("Scan again", for: .normal)
            self.defaultButton.isHidden = false
            self.secondaryButton.isHidden = false
        } else {
            self.defaultButton.isHidden = true
            self.secondaryButton.isHidden = false
            self.secondaryButton.setTitle("Scan Now", for: .normal)
        }
    }

    private func updateForScanningState(scan: JetpackScan) {
        let isPreparing = (scan.current?.progress ?? 0) == 0

        guard isPreparing else {
            self.iconImageView.image = UIImage(named: "jetpack-scan-state-progress")
            self.titleLabel.text = "Scanning files"
            self.descriptionLabel.text = "We will send you an email if security threats are found. In the meantime feel free to continue to use your site as normal, you can check back on progress at any time."
            self.defaultButton.isHidden = true
            self.secondaryButton.isHidden = true

            return
        }

        self.iconImageView.image = UIImage(named: "jetpack-scan-state-progress")
        self.titleLabel.text = "Preparing to scan"
        self.descriptionLabel.text = "We will send you an email if security threats are found. In the meantime feel free to continue to use your site as normal, you can check back on progress at any time."
        self.defaultButton.isHidden = true
        self.secondaryButton.isHidden = true
    }
}
