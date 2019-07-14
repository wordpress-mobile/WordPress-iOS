import Foundation

class ActivityListSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    
    static let height: CGFloat = 40
    static let identifier = "ActivityListSectionHeaderView"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        WPStyleGuide.applyBorderStyle(separator)
    }
}
