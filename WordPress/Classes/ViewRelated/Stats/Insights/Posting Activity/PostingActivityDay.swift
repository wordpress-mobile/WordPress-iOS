import UIKit

struct PostingActivityDayData {
    var date: Date
    var count: Int
}

class PostingActivityDay: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dayButton: UIButton!

    private var active = true
    private var dayData: PostingActivityDayData?
    private typealias PostActivityStyle = WPStyleGuide.Stats.PostingActivityRangeColors

    // MARK: - Configure

    func configure(dayData: PostingActivityDayData? = nil) {
        self.dayData = dayData
        active = dayData != nil
        configureButton()
    }

}

// MARK: - Private Extension

private extension PostingActivityDay {

    func configureButton() {
        dayButton.isEnabled = active

        if !active {
            dayButton.backgroundColor = .clear
            return
        }

        guard let dayData = dayData else {
            return
        }

        dayButton.backgroundColor = PostingActivityLegend.colorForCount(dayData.count)
    }

}
