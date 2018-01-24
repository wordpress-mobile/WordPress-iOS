import UIKit

class SiteCreationSitePreviewViewController: UIViewController {

    @IBOutlet weak var congratulationsView: UIView!
    @IBOutlet weak var congratulationsLabel: UILabel!
    @IBOutlet weak var siteReadyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        congratulationsView.backgroundColor = WPStyleGuide.wordPressBlue()

    }

    private func setLabelText() {
        congratulationsLabel.text = NSLocalizedString("Congratulations!", comment: "")
        siteReadyLabel.text = NSLocalizedString("Your site is ready.", comment: "")
    }

}
