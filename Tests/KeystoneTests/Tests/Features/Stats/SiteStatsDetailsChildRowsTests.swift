import Foundation
import Testing
import UIKit
import WordPressKit
import WordPressSharedObjC
@testable import WordPress

/// Covers detail tables where two expanded parents hold an equal child: a tag in two tag
/// groups, a link in two Clicks groups, and a post under two authors.
///
/// The suite is serialized because expanded rows live in the static
/// `StatsDataHelper.expandedRowLabelsDetails`.
@MainActor
@Suite(.serialized)
struct SiteStatsDetailsChildRowsTests {

    @Test func tagInTwoExpandedGroupsShowsUnderEach() throws {
        let table = DetailsTable(section: .insightsTagsAndCategories)
        let tag = { (name: String) in ["name": name, "type": "tag", "link": "https://example.com/tag/\(name)/"] }
        table.insightsStore.state.allTagsAndCategories = StatsTagsAndCategoriesInsight(jsonDictionary: [
            "tags": [
                ["views": 20, "tags": [tag("news"), tag("tech")]],
                ["views": 10, "tags": [tag("news"), tag("sport")]]
            ] as AnyObject
        ])
        table.insightsStore.state.allTagsAndCategoriesStatus = .success

        table.expand(["news, tech", "news, sport"])

        #expect(childNames(in: try table.snapshot()) == ["news", "tech", "news", "sport"])
    }

    @Test func linkInTwoExpandedClicksGroupsShowsUnderEach() throws {
        let table = DetailsTable(section: .periodClicks)
        let link = { (path: String, views: Int) in
            ["name": "example.com/\(path)/", "url": "https://example.com/\(path)/", "views": views] as [String: Any]
        }
        table.periodStore.state.topClicks = StatsTopClicksTimeIntervalData(
            date: table.date,
            period: .week,
            jsonDictionary: table.periodResponse([
                "clicks": [
                    ["name": "Group one", "views": 20, "children": [link("shared", 4), link("one", 16)]],
                    ["name": "Group two", "views": 10, "children": [link("shared", 4), link("two", 6)]]
                ],
                "total_clicks": 30,
                "other_clicks": 0
            ])
        )
        table.periodStore.state.topClicksStatus = .success

        table.expand(["Group one", "Group two"])

        #expect(
            childNames(in: try table.snapshot()) == [
                "example.com/shared/", "example.com/one/", "example.com/shared/", "example.com/two/"
            ]
        )
    }

    @Test func coAuthoredPostShowsUnderBothExpandedAuthors() throws {
        let table = DetailsTable(section: .periodAuthors)
        let post = { (id: Int, title: String, views: Int) in
            ["id": id, "title": title, "url": "https://example.com/?p=\(id)", "views": views] as [String: Any]
        }
        let sharedPost = post(1, "Co-authored post", 5)
        table.periodStore.state.topAuthors = StatsTopAuthorsTimeIntervalData(
            date: table.date,
            period: .week,
            jsonDictionary: table.periodResponse([
                "authors": [
                    ["name": "Author 1", "avatar": "", "views": 9, "posts": [sharedPost, post(2, "Post A", 4)]],
                    ["name": "Author 2", "avatar": "", "views": 8, "posts": [sharedPost, post(3, "Post B", 3)]]
                ],
                "other_views": 0
            ])
        )
        table.periodStore.state.topAuthorsStatus = .success

        table.expand(["Author 1", "Author 2"])

        #expect(childNames(in: try table.snapshot()) == ["Co-authored post", "Post A", "Co-authored post", "Post B"])
    }
}

// MARK: - Helpers

private extension SiteStatsDetailsChildRowsTests {
    func childNames(in snapshot: ImmuTableDiffableDataSourceSnapshot) -> [String] {
        snapshot.itemIdentifiers.compactMap { ($0.immuTableRow as? DetailExpandableChildRow)?.rowData.name }
    }
}

/// A stats detail table backed by real stores.
///
/// Each test creates its own instance and releases it on the main actor: the stores'
/// `Dispatcher` asserts when their receipts are released on another thread.
@MainActor
private final class DetailsTable {
    let date = Date()
    let insightsStore = StatsInsightsStore()
    let periodStore = StatsPeriodStore()
    private let section: StatSection
    private let viewModel: SiteStatsDetailsViewModel
    // Strong references: the view model keeps its delegates weak.
    private let detailsHandler = MockDetailsDelegate()
    private let referrerHandler = MockReferrerDelegate()
    private let savedExpandedRows = StatsDataHelper.expandedRowLabelsDetails

    /// Set the store state after `init`: `fetchDataFor` can mark the section as loading.
    init(section: StatSection) {
        self.section = section
        viewModel = SiteStatsDetailsViewModel(
            detailsDelegate: detailsHandler,
            referrerDelegate: referrerHandler,
            insightsStore: insightsStore,
            periodStore: periodStore
        )
        viewModel.fetchDataFor(statSection: section, selectedDate: date, selectedPeriod: .week)
    }

    deinit {
        StatsDataHelper.expandedRowLabelsDetails = savedExpandedRows
    }

    func expand(_ names: [String]) {
        StatsDataHelper.expandedRowLabelsDetails[section] = names
    }

    /// Wraps one day of a period endpoint's response. The parsers read only `days`.
    func periodResponse(_ day: [String: Any]) -> [String: AnyObject] {
        ["days": ["2026-11-23": day]] as [String: AnyObject]
    }

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
