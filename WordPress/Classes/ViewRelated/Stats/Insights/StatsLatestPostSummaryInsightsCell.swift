import UIKit


class StatsLatestPostSummaryInsightsCell: StatsBaseCell, LatestPostSummaryConfigurable {
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats
    private var lastPostInsight: StatsLastPostInsight?
    private var lastPostDetails: StatsPostDetails?
    private var postTitle = StatSection.noPostTitle

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
    }

    // MARK: - Public Configuration

    func configure(withInsightData lastPostInsight: StatsLastPostInsight?, chartData: StatsPostDetails?, andDelegate delegate: SiteStatsInsightsDelegate?) {
        siteStatsInsightsDelegate = delegate
        statSection = .insightsLatestPostSummary

        guard let lastPostInsight = lastPostInsight else {
            // Old cell shows Create Post if there's no latest post
            return
        }
    }
}
