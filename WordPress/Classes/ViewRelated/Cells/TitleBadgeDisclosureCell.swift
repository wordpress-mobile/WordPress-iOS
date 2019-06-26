
import UIKit

final class TitleBadgeDisclosureCell: WPTableViewCell {
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

    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryType = .disclosureIndicator
        accessoryView = nil

        customizeTagName()
        customizeTagCount()
    }

    private func customizeTagName() {
        cellTitle.font = WPStyleGuide.tableviewTextFont()
    }

    private func customizeTagCount() {
        cellBadge.font = WPStyleGuide.tableviewTextFont()
        cellBadge.textColor = .primary
        cellBadge.textAlignment = .center
        cellBadge.text = ""
        cellBadge.horizontalPadding = BadgeConstants.padding
        cellBadge.borderColor = .primary
        cellBadge.borderWidth = BadgeConstants.border
        cellBadge.cornerRadius = BadgeConstants.radius
    }

    override func prepareForReuse() {
        cellTitle.text = ""
        cellBadge.text = ""
    }
}
