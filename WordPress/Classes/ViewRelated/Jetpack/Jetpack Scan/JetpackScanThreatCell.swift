import UIKit

class JetpackScanThreatCell: UITableViewCell, NibReusable {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    func configure(with threat: JetpackScanThreat) {
        if let path = threat.fileName {
            let fileURL = URL(fileURLWithPath: path)
            titleLabel.text = fileURL.lastPathComponent
        }

        detailLabel.text = "Threat found (\(threat.signature))"
    }
}
