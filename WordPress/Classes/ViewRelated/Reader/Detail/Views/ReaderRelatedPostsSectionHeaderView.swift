import UIKit
import WordPressShared

class ReaderRelatedPostsSectionHeaderView: UITableViewHeaderFooterView, NibReusable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundColorView: UIView!

    static let height: CGFloat = 50

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        titleLabel.numberOfLines = 0
        titleLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .natural

        backgroundColorView.backgroundColor = .systemBackground
    }

}
