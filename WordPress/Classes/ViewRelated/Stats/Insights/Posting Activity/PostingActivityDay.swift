import UIKit

protocol PostingActivityDayDelegate: class {
    func daySelected(_ day: PostingActivityDay)
}

class PostingActivityDay: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dayButton: UIButton!
    private weak var delegate: PostingActivityDayDelegate?

    private var visible = true
    private var active = true
    private(set) var dayData: PostingStreakEvent?

    // MARK: - Configure

    func configure(dayData: PostingStreakEvent? = nil, delegate: PostingActivityDayDelegate? = nil) {
        self.dayData = dayData
        visible = dayData != nil
        active = delegate != nil
        self.delegate = delegate
        backgroundColor = .clear
        configureButton()
    }

    func unselect() {
        dayButton.backgroundColor = colorForCount()
    }
}

// MARK: - Private Extension

private extension PostingActivityDay {

    func configureButton() {
        dayButton.isGhostableDisabled = !visible
        dayButton.isEnabled = visible && active
        dayButton.backgroundColor = visible ? colorForCount() : .clear
    }

    func colorForCount() -> UIColor? {
        guard let dayData = dayData else {
            return .clear
        }

        return PostingActivityLegend.colorForCount(dayData.postCount)
    }

    @IBAction func dayButtonPressed(_ sender: UIButton) {
        dayButton.backgroundColor = WPStyleGuide.Stats.PostingActivityColors.selectedDay
        delegate?.daySelected(self)
    }

}
