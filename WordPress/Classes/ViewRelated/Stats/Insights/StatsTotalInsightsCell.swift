import UIKit
import WordPressShared


struct StatsTotalInsightsData {
    var count: Int
    var difference: Int
    var percentage: Int
    var sparklineData: [Int]? = nil
}

class StatsTotalInsightsCell: StatsBaseCell {
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private var lastPostInsight: StatsLastPostInsight?

    private let outerStackView = UIStackView()
    private let topInnerStackView = UIStackView()
    private let countLabel = UILabel()
    private let comparisonLabel = UILabel()
    private let graphView = SparklineView()

    // MARK: - Initialization

    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureView()
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    private func configureView() {
        configureStackViews()
        configureGraphView()
        configureLabels()
        configureConstraints()
    }

    private func configureStackViews() {
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.axis = .vertical
        outerStackView.spacing = Metrics.outerStackViewSpacing
        contentView.addSubview(outerStackView)

        topInnerStackView.axis = .horizontal
        topInnerStackView.spacing = Metrics.stackViewSpacing

        topInnerStackView.addArrangedSubviews([countLabel, graphView])
        outerStackView.addArrangedSubviews([topInnerStackView, comparisonLabel])
    }

    private func configureGraphView() {
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphView.setContentHuggingPriority(.required, for: .horizontal)
        graphView.setContentHuggingPriority(.required, for: .vertical)
    }

    private func configureLabels() {
        countLabel.font = WPStyleGuide.Stats.insightsCountFont
        countLabel.textColor = .text
        countLabel.text = "0"
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        countLabel.setContentHuggingPriority(.required, for: .vertical)

        comparisonLabel.font = .preferredFont(forTextStyle: .subheadline)
        comparisonLabel.textColor = .textSubtle
        comparisonLabel.text = "+87 (40%) compared to last week"
    }

    private func configureConstraints() {
        topConstraint = outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            outerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -StatsBaseCell.Metrics.padding),
            outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: StatsBaseCell.Metrics.padding),
            outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -StatsBaseCell.Metrics.padding),
            graphView.widthAnchor.constraint(equalTo: graphView.heightAnchor, multiplier: Metrics.graphViewAspectRatio),
            graphView.heightAnchor.constraint(equalTo: countLabel.heightAnchor)
        ])
    }

    func configure(count: Int, difference: Int, percentage: Int, sparklineData: [Int]? = nil, statSection: StatSection, siteStatsInsightsDelegate: SiteStatsInsightsDelegate?) {
        self.statSection = statSection
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        graphView.data = sparklineData ?? []
        graphView.chartColor = chartColor(for: difference)

        countLabel.text = count.abbreviatedString()
        let differenceText = difference > 0 ? TextContent.differenceHigher : TextContent.differenceLower
        let differencePrefix = difference < 0 ? "" : "+"

        comparisonLabel.text = String(format: differenceText, differencePrefix, difference.abbreviatedString(), percentage.abbreviatedString())
    }

    private func chartColor(for difference: Int) -> UIColor {
        return difference < 0 ? WPStyleGuide.Stats.neutralColor : WPStyleGuide.Stats.positiveColor
    }

    private enum Metrics {
        static let outerStackViewSpacing: CGFloat = 16.0
        static let stackViewSpacing: CGFloat = 8.0
        static let graphViewAspectRatio: CGFloat = 3.27
    }

    private enum TextContent {
        static let differenceHigher = NSLocalizedString("%@%@ (%@%%) higher than the previous week", comment: "Label shown on some metrics in the Stats Insights section, such as Comments count. The placeholders will be populated with a change and a percentage – e.g. '+17 (40%) higher than the previous week'")
        static let differenceLower = NSLocalizedString("%@%@ (%@%%) lower than the previous week", comment: "Label shown on some metrics in the Stats Insights section, such as Comments count. The placeholders will be populated with a change and a percentage – e.g. '-17 (40%) lower than the previous week'")
    }
}
