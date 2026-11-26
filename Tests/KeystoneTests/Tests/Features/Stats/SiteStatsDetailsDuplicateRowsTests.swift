import Foundation
import Testing
import UIKit
import WordPressKit
import WordPressSharedObjC
@testable import WordPress

/// Covers detail tables where the Stats API lists the same top-level entry twice, with the
/// same name, count and link.
@MainActor
struct SiteStatsDetailsDuplicateRowsTests {

    @Test func categoryListedTwiceShowsBothCopies() throws {
        let table = DetailsTable(section: .insightsTagsAndCategories)
        table.setTags(travelViews: [4, 4])

        #expect(rowNames(in: try table.snapshot()) == ["Recipes", "Travel", "Travel", "Garden"])
    }

    @Test func linkListedTwiceInClicksShowsBothCopies() throws {
        let table = DetailsTable(section: .periodClicks)
        let link = ["name": "example.com/same/", "url": "https://example.com/same/", "views": 5] as [String: Any]
        table.periodStore.state.topClicks = StatsTopClicksTimeIntervalData(
            date: Date(),
            period: .week,
            jsonDictionary: [
                "days": [
                    "2026-11-23": [
                        "clicks": [
                            ["name": "example.com/top/", "views": 20], link, link,
                            ["name": "example.com/end/", "views": 1]
                        ],
                        "total_clicks": 30,
                        "other_clicks": 0
                    ]
                ]
            ] as [String: AnyObject]
        )
        table.periodStore.state.topClicksStatus = .success

        #expect(
            rowNames(in: try table.snapshot()) == [
                "example.com/top/", "example.com/same/", "example.com/same/", "example.com/end/"
            ]
        )
    }

    @Test func newCountForOneCopyKeepsTheOtherCopy() throws {
        let table = DetailsTable(section: .insightsTagsAndCategories)
        table.setTags(travelViews: [4, 4])
        let before = rowItems(in: try table.snapshot())

        table.setTags(travelViews: [4, 5])
        let after = try table.snapshot()

        #expect(rowNames(in: after) == ["Recipes", "Travel", "Travel", "Garden"])
        // The diffable data source replaces an item only when it no longer finds an equal one.
        #expect(before.map { after.indexOfItem($0) != nil } == [true, true, false, true])
    }
}

// MARK: - Helpers

private extension SiteStatsDetailsDuplicateRowsTests {
    func rowItems(in snapshot: ImmuTableDiffableDataSourceSnapshot) -> [AnyHashableImmuTableRow] {
        snapshot.itemIdentifiers.filter { $0.immuTableRow is DetailExpandableRow }
    }

    func rowNames(in snapshot: ImmuTableDiffableDataSourceSnapshot) -> [String] {
        rowItems(in: snapshot).compactMap { ($0.immuTableRow as? DetailExpandableRow)?.rowData.name }
    }
}

/// A stats detail table backed by real stores.
///
/// Each test creates its own instance and releases it on the main actor: the stores'
/// `Dispatcher` asserts when their receipts are released on another thread.
@MainActor
private final class DetailsTable {
    let insightsStore = StatsInsightsStore()
    let periodStore = StatsPeriodStore()
    private let viewModel: SiteStatsDetailsViewModel
    // Strong references: the view model keeps its delegates weak.
    private let detailsHandler = MockDetailsDelegate()
    private let referrerHandler = MockReferrerDelegate()

    /// Set the store state after `init`: `fetchDataFor` can mark the section as loading.
    init(section: StatSection) {
        viewModel = SiteStatsDetailsViewModel(
            detailsDelegate: detailsHandler,
            referrerDelegate: referrerHandler,
            insightsStore: insightsStore,
            periodStore: periodStore
        )
        viewModel.fetchDataFor(statSection: section, selectedDate: Date(), selectedPeriod: .week)
    }

    /// Single-category groups, as in the crash reports: "Recipes", "Travel" once per count,
    /// then "Garden". The last row draws a different separator, so the copies sit before it.
    func setTags(travelViews: [Int]) {
        let category = { (name: String, views: Int) in
            [
                "views": views,
                "tags": [
                    ["name": name, "type": "category", "link": "https://example.com/?taxonomy=category&term=\(name)"]
                ]
            ] as [String: Any]
        }
        insightsStore.state.allTagsAndCategories = StatsTagsAndCategoriesInsight(jsonDictionary: [
            "tags": ([category("Recipes", 30)] + travelViews.map { category("Travel", $0) } + [category("Garden", 1)])
                as AnyObject
        ])
        insightsStore.state.allTagsAndCategoriesStatus = .success
    }

    /// Returns the view model's snapshot.
    ///
    /// UIKit raises `NSInternalInconsistencyException` for equal snapshot items. Catching it
    /// fails the test instead of ending the test process.
    func snapshot() throws -> ImmuTableDiffableDataSourceSnapshot {
        var snapshot = ImmuTableDiffableDataSourceSnapshot()
        try WPException.objcTry {
            snapshot = self.viewModel.tableViewSnapshot()
        }
        return snapshot
    }

    private final class MockDetailsDelegate: SiteStatsDetailsDelegate {}

    private final class MockReferrerDelegate: SiteStatsReferrerDelegate {
        func showReferrerDetails(_ data: StatsTotalRowData) {}
    }
}
