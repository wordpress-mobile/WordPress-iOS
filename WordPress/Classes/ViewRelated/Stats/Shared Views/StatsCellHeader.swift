import UIKit
import Gridicons

class StatsCellHeader: UIView, NibLoadable {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var manageInsightButton: UIButton!

    var showManageInsightButton = false
    private typealias Style = WPStyleGuide.Stats

    override func awakeFromNib() {
        super.awakeFromNib()
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
        manageInsightButton.isHidden = !showManageInsightButton
        manageInsightButton.tintColor = Style.ImageTintColor.grey.styleGuideColor
        manageInsightButton.setImage(Style.imageForGridiconType(.ellipsis, withTint: .grey), for: .normal)
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
