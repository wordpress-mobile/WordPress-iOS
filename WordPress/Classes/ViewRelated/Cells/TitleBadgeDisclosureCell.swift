
import UIKit

final class TitleBadgeDisclosureCell: WPTableViewCell {
    typealias BadgeTapBlock = () -> Void
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellBadge: BadgeLabel!

    private struct BadgeConstants {
        static let padding: CGFloat = 6.0
        static let radius: CGFloat = 9.0
        static let border: CGFloat = 1.0
    }

    var name: String? {
        didSet {
            cellTitle.text = name
        }
    }

    var count: Int = 0 {
        didSet {
            if count > 0 {
                cellBadge.text = String(count)
            }
        }
    }

    var badgeTap: BadgeTapBlock?

    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryType = .disclosureIndicator
        accessoryView = nil

        setupCellTitle()
        setupCellBadge()
    }

    private func setupCellTitle() {
        cellTitle.font = WPStyleGuide.tableviewTextFont()
    }

    private func setupCellBadge() {
        cellBadge.font = WPStyleGuide.tableviewTextFont()
        cellBadge.textColor = WPStyleGuide.wordPressBlue()
        cellBadge.textAlignment = .center
        cellBadge.text = ""
        cellBadge.horizontalPadding = BadgeConstants.padding
        cellBadge.borderColor = WPStyleGuide.wordPressBlue()
        cellBadge.borderWidth = BadgeConstants.border
        cellBadge.cornerRadius = BadgeConstants.radius

    }

    override func prepareForReuse() {
        cellTitle.text = ""
        cellBadge.text = ""
    }
}
