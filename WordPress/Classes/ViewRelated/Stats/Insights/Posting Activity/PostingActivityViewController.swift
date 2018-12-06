import UIKit

class PostingActivityViewController: UIViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = "PostingActivityViewController"

    // MARK: - Properties

    @IBOutlet weak var dayDataView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var legendView: UIView!
    @IBOutlet weak var separatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Posting Activity", comment: "Title for stats Posting Activity view.")
        addLegend()
        applyStyles()

        // Hide the day data view until a day is selected.
        dayDataView.isHidden = true
    }

}

// MARK: - Private Extension

private extension PostingActivityViewController {

    func addLegend() {
        let legend = PostingActivityLegend.loadFromNib()
        legendView.addSubview(legend)
    }

    func applyStyles() {
        Style.configureLabelAsPostingDate(dateLabel)
        Style.configureLabelAsPostingCount(postCountLabel)
        Style.configureViewAsSeperator(separatorLine)
    }
}
