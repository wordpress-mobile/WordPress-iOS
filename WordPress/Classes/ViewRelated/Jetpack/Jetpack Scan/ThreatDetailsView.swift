import UIKit
import Gridicons
import WordPressUI

class ThreatDetailsView: UIView, NibLoadable {

    // MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .basicBackground
    }

    // MARK: - Configure

    func configure(with viewModel: JetpackScanThreatViewModel) {

    }

}
