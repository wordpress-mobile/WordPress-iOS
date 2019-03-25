import UIKit

class SiteStatsTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backArrow: UIImageView!
    @IBOutlet weak var forwardArrow: UIImageView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    static let height: CGFloat = 44
    private typealias Style = WPStyleGuide.Stats


    // MARK: - View

    override func awakeFromNib() {
        applyStyles()
    }

    func configure(date: Date?) {

        guard let date = date else {
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        dateLabel.text = dateFormatter.string(from: date)
    }

}

private extension SiteStatsTableHeaderView {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(dateLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
        backArrow.image = Style.imageForGridiconType(.chevronLeft, withTint: .darkGrey)
        forwardArrow.image = Style.imageForGridiconType(.chevronRight)
    }

}
