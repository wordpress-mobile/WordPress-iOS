import Foundation
import Combine
import WordPressKit

class StatsSubscribersViewModel {
    private let store = StatsSubscribersStore()
    private var cancellables: Set<AnyCancellable> = []

    var tableViewSnapshot = PassthroughSubject<ImmuTableDiffableDataSourceSnapshot, Never>()

    init() {
    }

    func refreshData() {
        store.updateEmailsSummary()
    }

    // MARK: - Lifecycle

    func addObservers() {
        Publishers.MergeMany(store.emailsSummary)
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
        var snapshot = ImmuTableDiffableDataSourceSnapshot.multiSectionSnapshot(
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
                    itemSubtitle: "Latest emails",
                    dataSubtitle: "Opens/Clicks",
                    dataRows: emailsSummaryRows(emailsSummary),
                    statSection: .subscribersEmailsSummary,
                    siteStatsPeriodDelegate: nil)
            ]
        case .error:
            return errorRows(.subscribersEmailsSummary)
        }
    }

    func emailsSummaryRows(_ emailsSummary: StatsEmailsSummaryData) -> [StatsTotalRowData] {
        return emailsSummary.posts.map { post in
            StatsTotalRowData(name: post.title, data: "\(post.opens)/\(post.clicks)")
        }
    }
}
