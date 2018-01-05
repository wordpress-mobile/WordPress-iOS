import UIKit

class SiteCreationThemeSelectionHeaderView: UICollectionReusableView {

    // MARK: - Properties

    static let reuseIdentifier = "themeSelectionHeader"

    static let stepLabelText = NSLocalizedString("STEP 2 OF 4", comment: "Step for view.")
    static let stepDescrLabelText = NSLocalizedString("Get started fast with one of our popular themes. Once your site is created, you can browse and choose from hundreds more.", comment: "Shown during the theme selection step of the site creation flow.")

    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var stepDescrLabel: UILabel!

    // MARK: - Init

    override open func awakeFromNib() {
        super.awakeFromNib()
        stepLabel.text = SiteCreationThemeSelectionHeaderView.stepLabelText
        stepDescrLabel.text = SiteCreationThemeSelectionHeaderView.stepDescrLabelText
    }

}
