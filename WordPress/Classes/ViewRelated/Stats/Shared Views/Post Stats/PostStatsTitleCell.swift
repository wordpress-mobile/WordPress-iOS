import UIKit

class PostStatsTitleCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats
    private var postTitle: String?
    private var postURL: URL?
    private weak var postStatsDelegate: PostStatsDelegate?

    // MARK: - Configure

    // nix ? on URL (?)
    func configure(postTitle: String, postURL: URL?, postStatsDelegate: PostStatsDelegate? = nil) {
        self.postTitle = postTitle
        self.postURL = postURL
        self.postStatsDelegate = postStatsDelegate
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

        guard let postTitle = postTitle else {
            return
        }

        postTitleLabel.attributedText = Style.highlightString(postTitle, inString: postTitle)
    }

    @IBAction func didTapPostTitle(_ sender: UIButton) {
        guard let postURL = postURL else {
            return
        }

        postStatsDelegate?.displayWebViewWithURL?(postURL)
    }

}
