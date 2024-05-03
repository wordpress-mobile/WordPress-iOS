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
        store.updateSubscribersList(quantity: 10)
    }

    // MARK: - Lifecycle

    func addObservers() {
        Publishers.CombineLatest3(
            store.chartSummary.removeDuplicates(),
            store.emailsSummary.removeDuplicates(),
            store.subscribersList.removeDuplicates()
        )
        .sink { [weak self] _ in
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
        var snapshot = ImmuTableDiffableDataSourceSnapshot()
        snapshot.addSection(subscribersTotalsRows())
        snapshot.addSection(chartRows())
        snapshot.addSection(subscribersListRows())
        snapshot.addSection(emailsSummaryRows())
        tableViewSnapshot.send(snapshot)
    }

    func loadingRows(_ section: StatSection) -> [any StatsHashableImmuTableRow] {
        return [StatsGhostTopImmutableRow(statSection: section)]
    }

    func errorRows(_ section: StatSection) -> [any StatsHashableImmuTableRow] {
        return [StatsErrorRow(rowStatus: .error, statType: .subscribers, statSection: section)]
    }
}

// MARK: - Subscribers Totals

private extension StatsSubscribersViewModel {
    func subscribersTotalsRows() -> [any StatsHashableImmuTableRow] {
        switch store.subscribersList.value {
        case .loading, .idle:
            return loadingRows(.subscribersTotal)
        case .success(let subscribersData):
            return [
                TotalInsightStatsRow(
                    dataRow: .init(count: subscribersData.totalCount),
                    statSection: .subscribersTotal
                )
            ]
        case .error:
            return errorRows(.subscribersTotal)
        }
    }
}

// MARK: - Chart

private extension StatsSubscribersViewModel {
    func chartRows() -> [any StatsHashableImmuTableRow] {
        switch store.chartSummary.value {
        case .loading, .idle:
            return loadingRows(.subscribersChart)
        case .success(let chartSummary):
            let xAxisDates = chartSummary.history.map { $0.date }
            let viewsChart = StatsSubscribersLineChart(counts: chartSummary.history.map { $0.count })
            return [
                SubscriberChartRow(
                    history: chartSummary.history,
                    chartData: viewsChart.lineChartData,
                    chartStyling: viewsChart.lineChartStyling,
                    xAxisDates: xAxisDates,
                    statSection: .subscribersChart
                )
            ]
        case .error:
            return errorRows(.subscribersChart)
        }
    }
}

// MARK: - Emails Summary

private extension StatsSubscribersViewModel {
    func emailsSummaryRows() -> [any StatsHashableImmuTableRow] {
        switch store.emailsSummary.value {
        case .loading, .idle:
            return loadingRows(.subscribersEmailsSummary)
        case .success(let emailsSummary):
            return [
                TopTotalsPeriodStatsRow(
                    itemSubtitle: StatSection.ItemSubtitles.emailsSummary,
                    dataSubtitle: StatSection.DataSubtitles.emailsSummaryOpens,
                    secondDataSubtitle: StatSection.DataSubtitles.emailsSummaryClicks,
                    dataRows: emailsSummaryDataRows(emailsSummary),
                    statSection: .subscribersEmailsSummary,
                    siteStatsPeriodDelegate: viewMoreDelegate
                )
            ]
        case .error:
            return errorRows(.subscribersEmailsSummary)
        }
    }

    func emailsSummaryDataRows(_ emailsSummary: StatsEmailsSummaryData) -> [StatsTotalRowData] {
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

// MARK: - Subscribers List

private extension StatsSubscribersViewModel {
    func subscribersListRows() -> [any StatsHashableImmuTableRow] {
        switch store.subscribersList.value {
        case .loading, .idle:
            return loadingRows(.subscribersList)
        case .success(let subscribersData):
            return [
                TopTotalsPeriodStatsRow(
                    itemSubtitle: StatSection.ItemSubtitles.subscriber,
                    dataSubtitle: StatSection.DataSubtitles.since,
                    dataRows: subscribersListDataRows(subscribersData.subscribers),
                    statSection: .subscribersList,
                    siteStatsPeriodDelegate: viewMoreDelegate
                )
            ]
        case .error:
            return errorRows(.subscribersList)
        }
    }

    func subscribersListDataRows(_ subscribers: [StatsFollower]) -> [StatsTotalRowData] {
        return subscribers.map {
            return StatsTotalRowData(
                name: $0.name,
                data: $0.subscribedDate.relativeStringInPast(),
                userIconURL: $0.avatarURL,
                statSection: .subscribersList
            )
        }
    }
}
