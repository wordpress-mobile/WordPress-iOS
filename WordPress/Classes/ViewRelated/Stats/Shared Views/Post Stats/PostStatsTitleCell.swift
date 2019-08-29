import UIKit

class PostStatsTitleCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var bottomSeparatorLine: UIView!
    @IBOutlet private var labelsView: UIView!

    private typealias Style = WPStyleGuide.Stats
    private var postURL: URL?
    private weak var postStatsDelegate: PostStatsDelegate?

    // MARK: - Configure

    func configure(postTitle: String, postURL: URL?, postStatsDelegate: PostStatsDelegate? = nil) {
        self.postURL = postURL
        postTitleLabel.text = postTitle
        self.postStatsDelegate = postStatsDelegate
        applyStyles()
    }
}

private extension PostStatsTitleCell {

    func applyStyles() {
        titleLabel.text = NSLocalizedString("Showing stats for:", comment: "Label on Post Stats view indicating which post the stats are for.")

        labelsView.backgroundColor = .listForeground

        Style.configureCell(self)
        Style.configureLabelAsPostStatsTitle(titleLabel)
        Style.configureLabelAsPostTitle(postTitleLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    @IBAction func didTapPostTitle(_ sender: UIButton) {
        guard let postURL = postURL else {
            return
        }

        postStatsDelegate?.displayWebViewWithURL?(postURL)
    }

}
