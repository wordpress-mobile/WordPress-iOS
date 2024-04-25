import Foundation
import Combine
import WordPressKit

final class StatsSubscribersViewModel {
    private let store: StatsSubscribersStoreProtocol
    private var cancellables: Set<AnyCancellable> = []

    var tableViewSnapshot = PassthroughSubject<ImmuTableDiffableDataSourceSnapshot, Never>()
    weak var viewMoreDelegate: SiteStatsPeriodDelegate?

    init(store: StatsSubscribersStoreProtocol = StatsSubscribersStore()) {
        self.store = store
    }

    func refreshData() {
        store.updateChartSummary()
        store.updateEmailsSummary(quantity: 10, sortField: .postId)
    }

    // MARK: - Lifecycle

    func addObservers() {
        Publishers.CombineLatest(
            store.chartSummary.removeDuplicates(),
            store.emailsSummary.removeDuplicates()
        )
        .sink { [weak self] value in
            self?.updateTableViewSnapshot()
        }
        .store(in: &cancellables)
    }

    func removeObservers() {
        cancellables = []
    }
}

// MARK: - Table View Snapshot Updates

private extension StatsSubscribersViewModel {
    func updateTableViewSnapshot() {
        let rows: [any StatsHashableImmuTableRow] = [
            chartRow(),
            emailsSummaryRow(),
        ]
        let snapshot = ImmuTableDiffableDataSourceSnapshot.multiSectionSnapshot(rows)

        tableViewSnapshot.send(snapshot)
    }

    func loadingRow(_ section: StatSection) -> any StatsHashableImmuTableRow {
        return StatsGhostTopImmutableRow(statSection: section)
    }

    func errorRow(_ section: StatSection) -> any StatsHashableImmuTableRow {
        return StatsErrorRow(rowStatus: .error, statType: .subscribers, statSection: section)
    }
}

// MARK: - Chart

private extension StatsSubscribersViewModel {
    func chartRow() -> any StatsHashableImmuTableRow {
        switch store.chartSummary.value {
        case .loading, .idle:
            return loadingRow(.subscribersChart)
        case .success(let chartSummary):
            let xAxisDates = chartSummary.history.map { $0.date }
            let viewsChart = StatsSubscribersLineChart(counts: chartSummary.history.map { $0.count })
            let row = SubscriberChartRow(
                chartData: viewsChart.lineChartData,
                chartStyling: viewsChart.lineChartStyling,
                xAxisDates: xAxisDates,
                statSection: .subscribersChart
            )
            return row
        case .error:
            return errorRow(.subscribersChart)
        }
    }
}

// MARK: - Emails Summary

private extension StatsSubscribersViewModel {
    func emailsSummaryRow() -> any StatsHashableImmuTableRow {
        switch store.emailsSummary.value {
        case .loading, .idle:
            return loadingRow(.subscribersEmailsSummary)
        case .success(let emailsSummary):
            return TopTotalsPeriodStatsRow(
                itemSubtitle: Strings.titleColumn,
                dataSubtitle: Strings.opensColumn,
                secondDataSubtitle: Strings.clicksColumn,
                dataRows: emailsSummaryDataRow(emailsSummary),
                statSection: .subscribersEmailsSummary,
                siteStatsPeriodDelegate: viewMoreDelegate
            )
        case .error:
            return errorRow(.subscribersEmailsSummary)
        }
    }

    func emailsSummaryDataRow(_ emailsSummary: StatsEmailsSummaryData) -> [StatsTotalRowData] {
        return emailsSummary.posts.map {
            StatsTotalRowData(
                name: $0.title,
                data: $0.opens.abbreviatedString(),
                secondData: $0.clicks.abbreviatedString(),
                multiline: false,
                statSection: .subscribersEmailsSummary
            )
        }
    }
}

private extension StatsSubscribersViewModel {
    struct Strings {
        static let titleColumn = NSLocalizedString("stats.subscribers.emailsSummary.column.title", value: "Latest emails", comment: "A title for table's column that shows a name of an email")
        static let opensColumn = NSLocalizedString("stats.subscribers.emailsSummary.column.opens", value: "Opens", comment: "A title for table's column that shows a number of email openings")
        static let clicksColumn = NSLocalizedString("stats.subscribers.emailsSummary.column.clicks", value: "Clicks", comment: "A title for table's column that shows a number of times a post was opened from an email")
    }
}
