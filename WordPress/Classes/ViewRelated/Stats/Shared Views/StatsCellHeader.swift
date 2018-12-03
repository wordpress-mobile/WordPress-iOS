import UIKit
import Gridicons

class StatsCellHeader: UITableViewCell, NibLoadable {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var manageInsightButton: UIButton!

    private typealias Style = WPStyleGuide.Stats

    func configure(withTitle title: String) {
        headerLabel.text = title
        applyStyles()
    }

}

private extension StatsCellHeader {

    // MARK: - Configure

    func applyStyles() {
        Style.configureLabelAsHeader(headerLabel)
        configureManageInsightButton()
    }

    func configureManageInsightButton() {
        // TODO: remove this when Manage Insights implemented
        manageInsightButton.isHidden = true

        manageInsightButton.tintColor = Style.ImageTintColor.grey.styleGuideColor
        manageInsightButton.setImage(Style.imageForGridiconType(.ellipsis), for: .normal)
        manageInsightButton.accessibilityLabel = NSLocalizedString("Manage Insight", comment: "Action button to display manage insight options.")
    }

    // MARK: - Button Action

    @IBAction func manageInsightButtonPressed(_ sender: UIButton) {
        // TODO: remove alert when Manage Insights is added
        let alertController =  UIAlertController(title: "Manage Insight options will be shown here",
                                                 message: nil,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle("OK")
        alertController.presentFromRootViewController()
    }

}
