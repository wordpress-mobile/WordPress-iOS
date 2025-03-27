import Foundation
import WordPressShared

class ActivityListSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var backgroundColorView: UIView!

    static let height: CGFloat = 40
    static let identifier = "ActivityListSectionHeaderView"

    override func awakeFromNib() {
        super.awakeFromNib()
        WPStyleGuide.applyBorderStyle(separator)
        separator.backgroundColor = .separator

        backgroundColorView.backgroundColor = .systemGroupedBackground
    }
}
