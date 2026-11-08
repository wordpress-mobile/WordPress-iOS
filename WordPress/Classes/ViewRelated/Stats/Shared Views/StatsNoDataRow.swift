import UIKit
import WordPressShared

class StatsNoDataRow: UIView, Accessible {

    // MARK: - Properties

    let noDataLabel = UILabel.makeStatsLabel(
        text: "No data yet",
        textStyle: .body,
        textColor: UIColor(red: 0.667, green: 0.667, blue: 0.667, alpha: 1)
    )
    private let insightsNoDataLabel = NSLocalizedString(
        "No data yet",
        comment: "Text displayed when an Insights stat section has no data."
    )
    private let periodNoDataLabel = NSLocalizedString(
        "No data for this period",
        comment: "Text displayed when Period stat section has no data."
    )
    private let errorLabel = NSLocalizedString(
        "An error occurred.",
        comment: "Text displayed when a stat section failed to load."
    )

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyStatsXibRootDefaults(size: CGSize(width: 375, height: 45))

        backgroundColor = .white
        addSubview(noDataLabel)
        NSLayoutConstraint.activate([
            noDataLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            noDataLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: noDataLabel.trailingAnchor, constant: 16),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: noDataLabel.bottomAnchor, constant: 12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(forType statType: StatType, rowStatus: StoreFetchingStatus = .idle) {
        noDataLabel.text = text(for: statType, rowStatus: rowStatus)
        WPStyleGuide.Stats.configureLabelAsNoData(noDataLabel)
        backgroundColor = .secondarySystemGroupedBackground
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
