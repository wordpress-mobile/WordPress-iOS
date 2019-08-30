import UIKit

class StatsChildRowsView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var bottomSeperatorLine: UIView!

    var showBottomSeperatorLine = true {
        didSet {
            bottomSeperatorLine.isHidden = !showBottomSeperatorLine
        }
    }

    // MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .listForeground
        WPStyleGuide.Stats.configureViewAsSeparator(bottomSeperatorLine)
    }
}
