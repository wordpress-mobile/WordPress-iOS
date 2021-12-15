import UIKit

class StatsNoDataRow: UIView, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var noDataLabel: UILabel!
    private let insightsNoDataLabel = AppLocalizedString("No data yet",
                                                        comment: "Text displayed when an Insights stat section has no data.")
    private let periodNoDataLabel = AppLocalizedString("No data for this period",
                                                      comment: "Text displayed when Period stat section has no data.")
    private let errorLabel = AppLocalizedString("An error occurred.",
                                               comment: "Text displayed when a stat section failed to load.")

    // MARK: - Configure

    func configure(forType statType: StatType, rowStatus: StoreFetchingStatus = .idle) {
        noDataLabel.text = text(for: statType, rowStatus: rowStatus)
        WPStyleGuide.Stats.configureLabelAsNoData(noDataLabel)
        backgroundColor = .listForeground
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        isAccessibilityElement = true

        accessibilityLabel = noDataLabel.text
        accessibilityTraits = .staticText
    }
}

private extension StatsNoDataRow {
    func text(for statType: StatType, rowStatus: StoreFetchingStatus) -> String {
        switch rowStatus {
        case .idle, .success, .loading:
            return statType == .insights ? insightsNoDataLabel : periodNoDataLabel
        case .error:
            return errorLabel
        }
    }
}
