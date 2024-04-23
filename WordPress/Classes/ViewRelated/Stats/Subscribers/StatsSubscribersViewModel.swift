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
                    itemSubtitle: Strings.titleColumn,
                    dataSubtitle: Strings.opensColumn,
                    secondDataSubtitle: Strings.clicksColumn,
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

private extension StatsSubscribersViewModel {
    struct Strings {
        static let titleColumn = NSLocalizedString("stats.subscribers.emailsSummary.column.title", value: "Latest emails", comment: "A title for table's column that shows a name of an email")
        static let opensColumn = NSLocalizedString("stats.subscribers.emailsSummary.column.opens", value: "Opens", comment: "A title for table's column that shows a number of email openings")
        static let clicksColumn = NSLocalizedString("stats.subscribers.emailsSummary.column.clicks", value: "Clicks", comment: "A title for table's column that shows a number of times a post was opened from an email")
    }
}
