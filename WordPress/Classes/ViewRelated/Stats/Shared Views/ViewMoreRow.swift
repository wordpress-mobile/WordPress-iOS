import UIKit

class ViewMoreRow: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var viewMoreLabel: UILabel!

    // MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

}

// MARK: - Private Methods

private extension ViewMoreRow {

    func applyStyles() {
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = WPStyleGuide.Stats.actionTextColor
    }

    @IBAction func didTapViewMoreButton(_ sender: UIButton) {
        let alertController =  UIAlertController(title: "More will be shown here.",
                                                 message: nil,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle("OK")
        alertController.presentFromRootViewController()
    }

}
