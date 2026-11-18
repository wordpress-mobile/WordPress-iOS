import Foundation
import Testing
import UIKit
import WordPressKit
@testable import WordPress

/// Covers the Months and Years and Avg. Views Per Day detail tables, where month rows
/// from different years can show the same month name and the same count.
///
/// The suite is serialized because expanded years live in the static
/// `StatsDataHelper.expandedRowLabelsDetails`.
@MainActor
@Suite(.serialized)
struct SiteStatsDetailsPostStatsTests {

    @Test(arguments: [StatSection.postStatsMonthsYears, .postStatsAverageViews])
    func equalMonthsInTwoExpandedYearsAreSeparateRows(section: StatSection) throws {
        let table = PostStatsTable(section: section, april2025: 12)

        table.expand(["2026", "2025"])

        #expect(monthCounts(in: try table.snapshot()) == ["12", "16", "12", "15"])
    }

    @Test func collapsingAndReopeningAYearKeepsBothMonths() throws {
        let table = PostStatsTable(section: .postStatsMonthsYears, april2025: 12)

        table.expand(["2026", "2025"])
        #expect(monthCounts(in: try table.snapshot()) == ["12", "16", "12", "15"])

        table.expand(["2026"])
        #expect(monthCounts(in: try table.snapshot()) == ["12", "16"])

        table.expand(["2026", "2025"])
        #expect(monthCounts(in: try table.snapshot()) == ["12", "16", "12", "15"])
    }

    @Test func changedCountReplacesOnlyThatMonth() throws {
        let table = PostStatsTable(section: .postStatsMonthsYears, april2025: 12)
        table.expand(["2026", "2025"])
        let beforeMonths = monthItems(in: try table.snapshot())

        table.setPostDetails(april2025: 13)
        let after = try table.snapshot()

        #expect(monthCounts(in: after) == ["12", "16", "13", "15"])
        // The diffable data source replaces an item only when it no longer finds an equal one.
        #expect(beforeMonths.map { after.indexOfItem($0) != nil } == [true, true, false, true])
    }
}

// MARK: - Helpers

private extension SiteStatsDetailsPostStatsTests {
    func monthItems(in snapshot: ImmuTableDiffableDataSourceSnapshot) -> [AnyHashableImmuTableRow] {
        snapshot.itemIdentifiers.filter { $0.immuTableRow is DetailExpandableChildRow }
    }

    func monthCounts(in snapshot: ImmuTableDiffableDataSourceSnapshot) -> [String] {
        monthItems(in: snapshot).compactMap { ($0.immuTableRow as? DetailExpandableChildRow)?.rowData.data }
    }
}

/// A post stats detail table backed by a real `StatsPeriodStore`.
///
/// Each test creates its own instance and releases it on the main actor: the store's
/// `Dispatcher` asserts when its receipts are released on another thread.
@MainActor
private final class PostStatsTable {
    private let postID = 1046
    private let section: StatSection
    private let periodStore = StatsPeriodStore()
    private let viewModel: SiteStatsDetailsViewModel
    // Strong references: the view model keeps its delegates weak.
    private let detailsHandler = MockDetailsDelegate()
    private let referrerHandler = MockReferrerDelegate()
    private let savedExpandedRows = StatsDataHelper.expandedRowLabelsDetails

    init(section: StatSection, april2025: Int) {
        self.section = section
        viewModel = SiteStatsDetailsViewModel(
            detailsDelegate: detailsHandler,
            referrerDelegate: referrerHandler,
            insightsStore: StatsInsightsStore(),
            periodStore: periodStore
        )
        viewModel.fetchDataFor(statSection: section, postID: postID)
        // Set the data after `fetchDataFor`, which can mark the post stats as loading.
        setPostDetails(april2025: april2025)
    }

    deinit {
        StatsDataHelper.expandedRowLabelsDetails = savedExpandedRows
    }

    func expand(_ years: [String]) {
        StatsDataHelper.expandedRowLabelsDetails[section] = years
    }

    /// Seven years with positive totals, as in the reproduction. 2026 and 2025 both
    /// have April, with April 2025 set by the caller. Averages use the same numbers.
    func setPostDetails(april2025: Int) {
        var years: [String: [String: Int]] = [
            "2026": ["3": 16, "4": 12],
            "2025": ["3": 15, "4": april2025]
        ]
        for (offset, year) in (2020...2024).enumerated() {
            years[String(year)] = ["3": 10 + offset, "4": 6 + offset]
        }
        let months = years.mapValues { ["months": $0, "total": $0.values.reduce(0, +)] as [String: Any] }
        let json: [String: AnyObject] = [
            "date": "2026-11-18" as AnyObject,
            "views": 0 as AnyObject,
            "years": months as AnyObject,
            "averages": months as AnyObject,
            "weeks": [Any]() as AnyObject,
            "data": [Any]() as AnyObject
        ]
        periodStore.state.postStats[postID] = StatsPostDetails(jsonDictionary: json)
        periodStore.state.postStatsFetchingStatuses[postID] = .success
    }

    /// Returns the view model's real snapshot after checking that the expanded month rows differ.
    ///
    /// UIKit raises `NSInternalInconsistencyException` for duplicate snapshot items, which ends
    /// the test process. The view model's row builders are private, so the check builds the
    /// month rows with the same `StatsDataHelper` methods and fails the test instead.
    func snapshot() throws -> ImmuTableDiffableDataSourceSnapshot {
        let details = try #require(periodStore.getPostStats(for: postID))
        let yearsData = section == .postStatsAverageViews ? details.dailyAveragesPerMonth : details.monthlyBreakdown
        let rows = (StatsDataHelper.expandedRowLabelsDetails[section] ?? []).compactMap(Int.init)
            .flatMap {
                StatsDataHelper.childRowsForYear(StatsDataHelper.monthsFrom(yearsData: yearsData, forYear: $0))
            }
        for (index, row) in rows.enumerated() {
            try #require(!rows[..<index].contains(row), "Two month rows are equal, so the snapshot would reject them")
        }
        return viewModel.tableViewSnapshot()
    }

    private final class MockDetailsDelegate: SiteStatsDetailsDelegate {}

    private final class MockReferrerDelegate: SiteStatsReferrerDelegate {
        func showReferrerDetails(_ data: StatsTotalRowData) {}
    }
}
