import UIKit
import WordPressShared

class PostStatsTitleCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!

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

        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .secondaryLabel
        postTitleLabel.font = WPStyleGuide.navigationBarStandardFont
        backgroundColor = .secondarySystemGroupedBackground
    }

    @IBAction func didTapPostTitle(_ sender: UIButton) {
        guard let postURL else {
            return
        }
        postStatsDelegate?.displayWebViewWithURL?(postURL)
    }
}
