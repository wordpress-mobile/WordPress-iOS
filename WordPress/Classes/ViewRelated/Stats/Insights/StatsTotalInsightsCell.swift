import UIKit
import WordPressShared


struct StatsTotalInsightsData {
    var count: String
    var comparison: String = ""
}

class StatsTotalInsightsCell: StatsBaseCell {
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private var lastPostInsight: StatsLastPostInsight?

    private let outerStackView = UIStackView()
    private let topInnerStackView = UIStackView()
    private let countLabel = UILabel()
    private let comparisonLabel = UILabel()
    private let graphView = UIView()

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
        outerStackView.spacing = Metrics.stackViewSpacing
        contentView.addSubview(outerStackView)

        topInnerStackView.axis = .horizontal
        topInnerStackView.spacing = Metrics.stackViewSpacing

        topInnerStackView.addArrangedSubviews([countLabel, graphView])
        outerStackView.addArrangedSubviews([topInnerStackView, comparisonLabel])
    }

    private func configureGraphView() {
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphView.backgroundColor = .secondarySystemBackground
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

        comparisonLabel.font = .preferredFont(forTextStyle: .body)
        comparisonLabel.textColor = .textSubtle
        comparisonLabel.text = "+87 (40%) compared to last week"
    }

    private func configureConstraints() {
        topConstraint = outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: StatsBaseCell.Metrics.padding)

        NSLayoutConstraint.activate([
            topConstraint,
            outerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -StatsBaseCell.Metrics.padding),
            outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: StatsBaseCell.Metrics.padding),
            outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -StatsBaseCell.Metrics.padding),
            graphView.widthAnchor.constraint(equalTo: graphView.heightAnchor, multiplier: 2.55),
            graphView.heightAnchor.constraint(equalTo: countLabel.heightAnchor)
        ])
    }

    // TODO: This will need updating to pass some graph data too.
    // Assuming this will be something like a small array of ints
    func configure(count: String, statSection: StatSection, siteStatsInsightsDelegate: SiteStatsInsightsDelegate?) {
        self.statSection = statSection
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        countLabel.text = count
    }

    private enum Metrics {
        static let stackViewSpacing: CGFloat = 8.0
    }
}
