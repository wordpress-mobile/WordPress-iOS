import UIKit

struct PostingActivityDayData {
    var date: Date
    var count: Int
}

class PostingActivityDay: UIView, NibLoadable {

    @IBOutlet weak var dayButton: UIButton!

    private var active = true
    private var dayData: PostingActivityDayData?
    private typealias PostActivityStyle = WPStyleGuide.Stats.PostingActivityRangeColors

    func configure(dayData: PostingActivityDayData? = nil) {
        self.dayData = dayData
        active = dayData != nil
        configureButton()
    }

    func configureButton() {
        dayButton.isEnabled = active

        if !active {
            dayButton.backgroundColor = .clear
            return
        }

        guard let dayData = dayData else {
            return
        }

        dayButton.backgroundColor = {
            switch dayData.count {
            case 0:
                return PostActivityStyle.lightGrey
            case 1...2:
                return PostActivityStyle.lightBlue
            case 3...5:
                return PostActivityStyle.mediumBlue
            case 6...7:
                return PostActivityStyle.darkBlue
            default:
                return PostActivityStyle.darkGrey
            }
        }()
    }

}
