import UIKit

/// Convenience struct to contain information about a single day displayed in Posting Activity.
///
struct PostingActivityDayData {
    var date: Date
    var count: Int
}

class PostingActivityDay: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dayButton: UIButton!

    private var visible = true
    private var dayData: PostingActivityDayData?
    private typealias PostActivityStyle = WPStyleGuide.Stats.PostingActivityRangeColors

    // MARK: - Configure

    func configure(dayData: PostingActivityDayData? = nil) {
        self.dayData = dayData
        visible = dayData != nil
        configureButton()
    }

}

// MARK: - Private Extension

private extension PostingActivityDay {

    func configureButton() {
        dayButton.isEnabled = visible

        if !visible {
            dayButton.backgroundColor = .clear
            return
        }

        guard let dayData = dayData else {
            return
        }

        dayButton.backgroundColor = PostingActivityLegend.colorForCount(dayData.count)
    }

}
