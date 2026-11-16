import UIKit
import WordPressShared
import WordPressUI

class ThemeBrowserSectionHeaderView: UICollectionReusableView, NibLoadable {
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var stackView: UIStackView!

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

        // Keep the heading inside the safe area, in line with the theme cards below it. The xib's
        // side constraints are removed at build time.
        let margin: CGFloat = 20
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: margin),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: margin)
        ])

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
