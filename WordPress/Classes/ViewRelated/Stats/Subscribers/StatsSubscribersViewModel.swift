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
        store.updateEmailsSummary(quantity: 10, sortField: .postId)
    }

    // MARK: - Lifecycle

    func addObservers() {
        Publishers.MergeMany(store.emailsSummary)
            .removeDuplicates()
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
        let snapshot = ImmuTableDiffableDataSourceSnapshot.multiSectionSnapshot(
            emailsSummaryRows()
        )
        tableViewSnapshot.send(snapshot)
    }

    func loadingRows(_ section: StatSection) -> [any StatsHashableImmuTableRow] {
        return [StatsGhostTopImmutableRow(statSection: section)]
    }

    func errorRows(_ section: StatSection) -> [any StatsHashableImmuTableRow] {
        return [StatsErrorRow(rowStatus: .error, statType: .subscribers, statSection: section)]
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
