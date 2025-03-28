import UIKit
import WordPressShared
import WordPressUI

class ThemeBrowserSectionHeaderView: UICollectionReusableView {
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var countLabel: UILabel!

    // MARK: - Constants

    @objc static let height = 40

    @objc var themeCount: NSInteger = 0 {
        didSet {
            if themeCount > 0 {
                countLabel.text = "  " + String(themeCount) + "  "
                countLabel.isHidden = false
            } else {
                countLabel.isHidden = true
            }
        }
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        countLabel.isHidden = true
        applyStyles()
    }

    fileprivate func applyStyles() {
        descriptionLabel.textColor = UIAppColor.neutral(.shade50)
        countLabel.textColor = UIAppColor.neutral(.shade50)
        countLabel.layer.borderColor = UIAppColor.neutral(.shade40).cgColor
        countLabel.layer.borderWidth = 1.0
        countLabel.layer.cornerRadius = 9.0
    }
}
