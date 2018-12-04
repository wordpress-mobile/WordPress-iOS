import UIKit

struct PostingActivityDayData {
    var date: Date
    var count: Int
}

class PostingActivityDay: UIView, NibLoadable {

    @IBOutlet weak var dayButton: UIButton!

}
