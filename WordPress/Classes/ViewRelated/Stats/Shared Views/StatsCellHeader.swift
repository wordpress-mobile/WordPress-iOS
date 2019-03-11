import UIKit
import Gridicons

class StatsCellHeader: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var manageInsightButton: UIButton!
    @IBOutlet weak var stackViewTopConstraint: NSLayoutConstraint!

    private typealias Style = WPStyleGuide.Stats
    private var defaultStackViewTopConstraint: CGFloat = 0

    // MARK: - Configure

    override func awakeFromNib() {
        defaultStackViewTopConstraint = stackViewTopConstraint.constant
    }

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
        updateStackView()
    }

    func updateStackView() {
        // Only show the top padding if there is actually a label.
        stackViewTopConstraint.constant = headerLabel.text == "" ? 0 : defaultStackViewTopConstraint
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
