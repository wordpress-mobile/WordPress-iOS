import UIKit

protocol PostingActivityDayDelegate: class {
    func daySelected(_ day: PostingActivityDay)
}

/// Convenience struct to contain information about a single day displayed in Posting Activity.
///
struct PostingActivityDayData {
    var date: Date
    var count: Int
}

class PostingActivityDay: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dayButton: UIButton!
    private weak var delegate: PostingActivityDayDelegate?

    private var visible = true
    private var active = true
    private(set) var dayData: PostingActivityDayData?

    // MARK: - Configure

    func configure(dayData: PostingActivityDayData? = nil, delegate: PostingActivityDayDelegate? = nil) {
        self.dayData = dayData
        visible = dayData != nil
        active = delegate != nil
        self.delegate = delegate
        configureButton()
    }

    func unselect() {
        dayButton.backgroundColor = colorForCount()
    }
}

// MARK: - Private Extension

private extension PostingActivityDay {

    func configureButton() {
        dayButton.isEnabled = visible && active
        dayButton.backgroundColor = visible ? colorForCount() : .clear
    }

    func colorForCount() -> UIColor? {
        guard let dayData = dayData else {
            return .clear
        }

        return PostingActivityLegend.colorForCount(dayData.count)
    }

    @IBAction func dayButtonPressed(_ sender: UIButton) {
        dayButton.backgroundColor = WPStyleGuide.Stats.PostingActivityColors.orange
        delegate?.daySelected(self)
    }

}
