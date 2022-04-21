import UIKit

struct StatsMostPopularTimeData {
    var mostPopularDayTitle: String
    var mostPopularTimeTitle: String
    var mostPopularDay: String
    var mostPopularTime: String
    var dayPercentage: String
    var timePercentage: String
}

class StatsMostPopularTimeInsightsCell: StatsBaseCell {
    private var data: StatsMostPopularTimeData? = nil
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    // MARK: - Subviews

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

    // MARK: - View Configuration

    private func configureView() {
        let stackView = makeOuterStackView()
        contentView.addSubview(stackView)

        topConstraint = stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: StatsBaseCell.Metrics.padding)

        NSLayoutConstraint.activate([
            topConstraint,
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -StatsBaseCell.Metrics.padding),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: StatsBaseCell.Metrics.padding),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -StatsBaseCell.Metrics.padding),
        ])
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

        let middleLabel = UILabel()
        middleLabel.textColor = .text
        middleLabel.font = .preferredFont(forTextStyle: .title1).bold()

        let bottomLabel = UILabel()
        bottomLabel.textColor = .textSubtle
        bottomLabel.font = .preferredFont(forTextStyle: .body)

        verticalStackView.spacing = Metrics.verticalStackViewSpacing
        verticalStackView.addArrangedSubviews([topLabel, middleLabel, bottomLabel])

        return (topLabel: topLabel, middleLabel: middleLabel, bottomLabel: bottomLabel)
    }

    // MARK: Public configuration

    func configure(data: StatsMostPopularTimeData?, siteStatsInsightsDelegate: SiteStatsInsightsDelegate?) {
        self.data = data
        self.statSection = .insightsMostPopularTime
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate

        if let data = data {
            topLeftLabel.text = data.mostPopularDayTitle
            middleLeftLabel.text = data.mostPopularDay
            bottomLeftLabel.text = data.dayPercentage

            topRightLabel.text = data.mostPopularTimeTitle
            middleRightLabel.text = data.mostPopularTime
            bottomRightLabel.text = data.timePercentage
        }
    }

    private enum Metrics {
        static let horizontalStackViewSpacing: CGFloat = 32.0
        static let verticalStackViewSpacing: CGFloat = 8.0
        static let dividerWidth: CGFloat = 1.0
    }
}

