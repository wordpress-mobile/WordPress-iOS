import UIKit

class StatsNoDataRow: UIView, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var noDataLabel: UILabel!
    private let insightsNoDataLabel = NSLocalizedString("No data yet",
                                                        comment: "Text displayed when an Insights stat section has no data.")
    private let periodNoDataLabel = NSLocalizedString("No data for this period",
                                                      comment: "Text displayed when Period stat section has no data.")

    // MARK: - Configure

    func configure(forType statType: StatType) {
        noDataLabel.text = statType == .insights ? insightsNoDataLabel : periodNoDataLabel
        WPStyleGuide.Stats.configureLabelAsNoData(noDataLabel)
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        isAccessibilityElement = true

        accessibilityLabel = noDataLabel.text
        accessibilityTraits = .staticText
    }
}
