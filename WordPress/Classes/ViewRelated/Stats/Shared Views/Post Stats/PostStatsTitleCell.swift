import UIKit

class PostStatsTitleCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(postTitle: String) {
        postTitleLabel.text = postTitle
        applyStyles()
    }
}

private extension PostStatsTitleCell {

    func applyStyles() {
        titleLabel.text = NSLocalizedString("Showing stats for:", comment: "Label on Post Stats view indicating which post the stats are for.")
        Style.configureLabelAsPostStatsTitle(titleLabel)
        Style.configureLabelAsPostTitle(postTitleLabel)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

}
