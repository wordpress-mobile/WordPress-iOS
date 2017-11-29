import UIKit

class ThemeSelectionHeaderView: UICollectionReusableView {

    // MARK - Properties

    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var stepDescrLabel: UILabel!

    open static let reuseIdentifier = "themeSelectionHeader"

    // MARK: - Init

    override open func awakeFromNib() {
        super.awakeFromNib()

        stepLabel.text = NSLocalizedString("STEP 2 OF 4", comment: "Step for view.")
        stepDescrLabel.text = NSLocalizedString("Get started fast with one of our popular themes. Once your site is created, you can browse and choose from hundreds more.", comment: "Site theme instruction.")
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
    }
}
