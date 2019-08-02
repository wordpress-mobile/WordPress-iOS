import UIKit

class PostingActivityLegend: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var fewerPostsLabel: UILabel!
    @IBOutlet weak var colorsStackView: UIStackView!
    @IBOutlet weak var morePostsLabel: UILabel!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        addColors()
    }

    // MARK: - Public Class Methods

    static func colorForCount(_ count: Int) -> UIColor? {
        switch count {
        case 0:
            return Style.PostingActivityColors.range1
        case 1...2:
            return Style.PostingActivityColors.range2
        case 3...5:
            return Style.PostingActivityColors.range3
        case 6...7:
            return Style.PostingActivityColors.range4
        default:
            return Style.PostingActivityColors.range5
        }
    }

}

// MARK: - Private Extension

private extension PostingActivityLegend {

    func applyStyles() {
        fewerPostsLabel.text = NSLocalizedString("Fewer Posts", comment: "Label for the posting activity legend.")
        morePostsLabel.text = NSLocalizedString("More Posts", comment: "Label for the posting activity legend.")
        Style.configureLabelAsPostingLegend(fewerPostsLabel)
        Style.configureLabelAsPostingLegend(morePostsLabel)
    }

    func addColors() {
        var numberInRange = 0
        for _ in 1...5 {
            let dayView = PostingActivityDay.loadFromNib()
            dayView.configure()
            dayView.dayButton.backgroundColor = PostingActivityLegend.colorForCount(numberInRange)
            colorsStackView.addArrangedSubview(dayView)
            numberInRange += 2
        }
    }

}
