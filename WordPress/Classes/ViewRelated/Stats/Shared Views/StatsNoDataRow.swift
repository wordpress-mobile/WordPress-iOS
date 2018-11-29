import UIKit

class StatsNoDataRow: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var noDataLabel: UILabel!
    private let dataLabel = NSLocalizedString("No data yet", comment: "Text displayed when a stats section has no data.")

    // MARK: - Configure

    override func awakeFromNib() {
        noDataLabel.text = dataLabel
        WPStyleGuide.Stats.configureLabelAsNoData(noDataLabel)
    }

}
