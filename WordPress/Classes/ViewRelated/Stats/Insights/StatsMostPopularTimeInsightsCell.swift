import UIKit

class StatsMostPopularTimeInsightsCell: StatsBaseCell {
    private var data: StatsMostPopularTimeData? = nil
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    // MARK: - Subviews

    private var outerStackView: UIStackView!

    private var noDataLabel: UILabel!

    private var topLeftLabel: UILabel!
    private var middleLeftLabel: UILabel!
    private var bottomLeftLabel: UILabel!

    private var topRightLabel: UILabel!
    private var middleRightLabel: UILabel!
    private var bottomRightLabel: UILabel!

    // MARK: - Initialization

    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureView()
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        displayNoData(show: false)
    }

    // MARK: - View Configuration

    private func configureView() {
        selectionStyle = .none

        outerStackView = makeOuterStackView()
        contentView.addSubview(outerStackView)

        topConstraint = outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: StatsBaseCell.Metrics.padding)

        NSLayoutConstraint.activate([
            topConstraint!,
            outerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -StatsBaseCell.Metrics.padding),
            outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: StatsBaseCell.Metrics.padding),
            outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -StatsBaseCell.Metrics.padding),
        ])

        noDataLabel = makeNoDataLabel()
        contentView.addSubview(noDataLabel)
        outerStackView.pinSubviewToAllEdges(noDataLabel)
        noDataLabel.isHidden = true
    }

    private func makeOuterStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Metrics.horizontalStackViewSpacing

        let leftStackView = makeLeftStackView()
        let rightStackView = makeRightStackView()
        let divider = makeVerticalDivider()

        stackView.addArrangedSubviews([leftStackView, divider, rightStackView])

        configureInnerStackViews(leftStackView: leftStackView,
                                 rightStackView: rightStackView)

        NSLayoutConstraint.activate([
            leftStackView.widthAnchor.constraint(equalTo: rightStackView.widthAnchor),
            divider.widthAnchor.constraint(equalToConstant: Metrics.dividerWidth)
        ])

        return stackView
    }

    private func makeLeftStackView() -> UIStackView {
        let leftStackView = UIStackView()
        leftStackView.translatesAutoresizingMaskIntoConstraints = false
        leftStackView.axis = .vertical

        return leftStackView
    }

    private func makeRightStackView() -> UIStackView {
        let rightStackView = UIStackView()
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.axis = .vertical

        return rightStackView
    }

    private func makeVerticalDivider() -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        WPStyleGuide.Stats.configureViewAsVerticalSeparator(divider)

        return divider
    }

    private func configureInnerStackViews(leftStackView: UIStackView,
                                          rightStackView: UIStackView) {
        let leftLabels = configure(verticalStackView: leftStackView)
        let rightLabels = configure(verticalStackView: rightStackView)

        topLeftLabel = leftLabels.topLabel
        middleLeftLabel = leftLabels.middleLabel
        bottomLeftLabel = leftLabels.bottomLabel

        topRightLabel = rightLabels.topLabel
        middleRightLabel = rightLabels.middleLabel
        bottomRightLabel = rightLabels.bottomLabel
    }

    private func configure(verticalStackView: UIStackView) -> (topLabel: UILabel, middleLabel: UILabel, bottomLabel: UILabel) {
        let topLabel = UILabel()
        topLabel.textColor = .text
        topLabel.font = .preferredFont(forTextStyle: .body)
        topLabel.numberOfLines = 0

        let middleLabel = UILabel()
        middleLabel.textColor = .text
        middleLabel.font = WPStyleGuide.Stats.insightsCountFont
        middleLabel.adjustsFontForContentSizeCategory = true
        middleLabel.numberOfLines = 0

        let bottomLabel = UILabel()
        bottomLabel.textColor = .textSubtle
        bottomLabel.font = .preferredFont(forTextStyle: .body)
        bottomLabel.numberOfLines = 0

        verticalStackView.spacing = Metrics.verticalStackViewSpacing
        verticalStackView.addArrangedSubviews([topLabel, middleLabel, bottomLabel])

        return (topLabel: topLabel, middleLabel: middleLabel, bottomLabel: bottomLabel)
    }

    private func makeNoDataLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .textSubtle
        label.numberOfLines = 0
        label.text = TextContent.noData

        return label
    }

    private func displayNoData(show: Bool) {
        outerStackView.subviews.forEach({ $0.isHidden = show })
        noDataLabel.isHidden = !show
    }

    // MARK: Public configuration

    func configure(data: StatsMostPopularTimeData?, siteStatsInsightsDelegate: SiteStatsInsightsDelegate?) {
        self.data = data
        self.statSection = .insightsMostPopularTime
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        guard let data = data else {
            displayNoData(show: true)
            return
        }

        topLeftLabel.text = data.mostPopularDayTitle
        middleLeftLabel.text = data.mostPopularDay
        bottomLeftLabel.text = data.dayPercentage

        topRightLabel.text = data.mostPopularTimeTitle
        middleRightLabel.text = data.mostPopularTime
        bottomRightLabel.text = data.timePercentage
    }

    private enum Metrics {
        static let horizontalStackViewSpacing: CGFloat = 16.0
        static let verticalStackViewSpacing: CGFloat = 8.0
        static let dividerWidth: CGFloat = 1.0
    }

    private enum TextContent {
        static let noData = NSLocalizedString("stats.insights.mostPopularTime.noData", value: "Not enough activity. Check back later when your site's had more visitors!", comment: "Hint displayed on the 'Most Popular Time' stats card when a user's site hasn't yet received enough traffic.")
    }
}

// MARK: - Data / View Model

struct StatsMostPopularTimeData {
    var mostPopularDayTitle: String
    var mostPopularTimeTitle: String
    var mostPopularDay: String
    var mostPopularTime: String
    var dayPercentage: String
    var timePercentage: String
}

// MARK: - Model Formatting Helpers

extension StatsAnnualAndMostPopularTimeInsight {
    func formattedMostPopularDay() -> String? {
        guard var mostPopularWeekday = mostPopularDayOfWeek.weekday else {
            return nil
        }

        var calendar = Calendar.init(identifier: .gregorian)
        calendar.locale = Locale.autoupdatingCurrent

        // Back up mostPopularWeekday by 1 to get correct index for standaloneWeekdaySymbols.
        mostPopularWeekday = mostPopularWeekday == 0 ? calendar.standaloneWeekdaySymbols.count - 1 : mostPopularWeekday - 1
        return calendar.standaloneWeekdaySymbols[mostPopularWeekday]
    }

    func formattedMostPopularTime() -> String? {
        var calendar = Calendar.init(identifier: .gregorian)
        calendar.locale = Locale.autoupdatingCurrent

        guard let hour = mostPopularHour.hour,
              let timeModifiedDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) else {
            return nil
        }

        let timeFormatter = DateFormatter()
        timeFormatter.setLocalizedDateFormatFromTemplate("h a")

        return timeFormatter.string(from: timeModifiedDate).uppercased()
    }
}
