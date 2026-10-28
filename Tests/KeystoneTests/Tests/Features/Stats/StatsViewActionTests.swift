import Testing
import UIKit
import WordPressKit
@testable import WordPress

/// Taps every button and control in the Stats views and checks that each one reaches its delegate.
@MainActor
struct StatsViewActionTests {
    private let spy = StatsActionSpy()

    // MARK: - Shared rows

    @Test func viewMoreRowReportsItsSection() throws {
        let row = ViewMoreRow()
        row.configure(statSection: .periodReferrers, delegate: spy)

        try #require(buttons(in: row).first).sendActions(for: .touchUpInside)

        #expect(spy.viewMoreSections == [.periodReferrers])
    }

    @Test func totalRowOpensItsLink() throws {
        let url = try #require(URL(string: "https://example.com"))
        let row = StatsTotalRow()
        row.configure(
            rowData: StatsTotalRowData(
                name: "Row",
                data: "1",
                showDisclosure: true,
                disclosureURL: url,
                statSection: .periodClicks
            ),
            delegate: spy
        )

        row.disclosureButton.sendActions(for: .touchUpInside)

        #expect(spy.openedURLs == [url])
    }

    @Test func totalRowShowsItsMedia() {
        let row = StatsTotalRow()
        row.configure(
            rowData: StatsTotalRowData(name: "Video", data: "1", mediaID: 42, statSection: .periodVideos),
            delegate: spy
        )

        row.disclosureButton.sendActions(for: .touchUpInside)

        #expect(spy.mediaIDs == [42])
    }

    @Test func totalRowWithChildrenToggles() {
        let child = StatsTotalRowData(name: "Child", data: "1", statSection: .insightsTagsAndCategories)
        let row = StatsTotalRow()
        row.configure(
            rowData: StatsTotalRowData(
                name: "Parent",
                data: "2",
                childRows: [child],
                statSection: .insightsTagsAndCategories
            ),
            delegate: spy
        )

        row.disclosureButton.sendActions(for: .touchUpInside)

        #expect(spy.toggledRows == 1)
        #expect(row.expanded)
    }

    @Test func cellHeaderManagesItsInsight() throws {
        let cell = try dequeue(CellHeaderRow(statSection: .insightsAllTime)) as StatsCellHeader
        cell.configure(statSection: .insightsAllTime, siteStatsInsightsDelegate: spy)

        try #require(buttons(in: cell).first).sendActions(for: .touchUpInside)

        #expect(spy.managedInsights == [.insightsAllTime])
    }

    @Test func dateHeaderMovesBackAndForward() throws {
        let calendar = Calendar.current
        let date = try #require(calendar.date(from: DateComponents(year: 2024, month: 3, day: 10, hour: 12)))
        let mostRecent = try #require(calendar.date(byAdding: .day, value: 5, to: date))
        let header = SiteStatsTableHeaderView()
        header.configure(date: date, period: .day, delegate: spy, mostRecentDate: mostRecent)

        let navigation = buttons(in: header)
        try #require(navigation.count == 2)
        navigation[0].sendActions(for: .touchUpInside)
        navigation[1].sendActions(for: .touchUpInside)

        let changes = spy.dateChanges.compactMap { $0 }.map { calendar.dateComponents([.day], from: date, to: $0).day }
        #expect(changes == [-1, 0])
    }

    // MARK: - Insights cells

    @Test func customizeInsightsButtons() throws {
        let cell = try dequeue(CustomizeInsightsRow(siteStatsInsightsDelegate: spy)) as CustomizeInsightsCell
        CustomizeInsightsRow(siteStatsInsightsDelegate: spy).configureCell(cell)

        for button in buttons(in: cell) {
            button.sendActions(for: .touchUpInside)
        }

        #expect(spy.customizeDismissTaps == 1)
        #expect(spy.customizeTryTaps == 1)
    }

    @Test func growAudienceButtons() throws {
        let row = GrowAudienceRow(
            hintType: .social,
            allTimeViewsCount: 3,
            isNudgeCompleted: false,
            siteStatsInsightsDelegate: spy,
            statSection: .insightsAddInsight
        )
        let cell = try dequeue(row) as GrowAudienceCell
        row.configureCell(cell)

        let tapped = buttons(in: cell)
        try #require(tapped.count == 2)
        tapped.forEach { $0.sendActions(for: .touchUpInside) }

        #expect(spy.growAudienceDismissedHints == [.social])
        #expect(spy.postSharingTaps == 1)
    }

    @Test func postingActivityDaySelects() throws {
        let day = PostingActivityDay()
        let delegate = PostingDaySpy()
        day.configure(dayData: PostingStreakEvent(date: Date(), postCount: 2), delegate: delegate)

        day.dayButton.sendActions(for: .touchUpInside)

        #expect(delegate.selectedDays == [day])
    }

    @Test func postingActivityViewMore() throws {
        let row = PostingActivityRow(
            monthsData: [],
            siteStatsInsightsDelegate: spy,
            statSection: .insightsPostingActivity
        )
        let cell = try dequeue(row) as PostingActivityCell
        row.configureCell(cell)

        let viewMore = try #require(buttons(in: cell).first { !($0.superview is PostingActivityDay) })
        viewMore.sendActions(for: .touchUpInside)

        #expect(spy.postingActivityDetailsTaps == 1)
    }

    @Test func twoColumnViewMore() throws {
        let data = [
            StatsTwoColumnRowData(
                leftColumnName: "Posts",
                leftColumnData: "1",
                rightColumnName: "Views",
                rightColumnData: "2"
            )
        ]
        let row = TwoColumnStatsRow(
            dataRows: data,
            statSection: .insightsAnnualSiteStats,
            siteStatsInsightsDelegate: spy
        )
        let cell = try dequeue(row) as TwoColumnCell
        row.configureCell(cell)

        try #require(buttons(in: cell).first).sendActions(for: .touchUpInside)

        #expect(spy.viewMoreSections == [.insightsAnnualSiteStats])
    }

    @Test func viewsVisitorsSegmentChanges() throws {
        let summary = try #require(
            try StatsMockDataLoader.createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-14.json")
        )
        let delegate = ViewsVisitorsSpy()
        let row = try #require(
            SiteStatsImmuTableRows.viewVisitorsImmuTableRows(
                summary,
                selectedSegment: .views,
                periodDate: Date(),
                siteStatsInsightsDelegate: nil,
                viewsAndVisitorsDelegate: delegate
            )
            .first
        )
        let cell = try dequeue(row) as ViewsVisitorsLineChartCell
        row.configureCell(cell)

        let control = try #require(segmentedControls(in: cell).first)
        control.selectedSegmentIndex = 1
        control.sendActions(for: .valueChanged)

        #expect(delegate.selectedSegments == [1])
    }

    // MARK: - Helpers

    private func dequeue<Cell: UITableViewCell>(_ row: any ImmuTableRow) throws -> Cell {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 800))
        ImmuTable.registerRows([type(of: row)], tableView: tableView)
        let cell = try #require(
            tableView.dequeueReusableCell(withIdentifier: type(of: row).cell.reusableIdentifier) as? Cell
        )
        cell.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        cell.layoutIfNeeded()
        return cell
    }

    private func buttons(in view: UIView) -> [UIButton] {
        view.subviews.flatMap { subview -> [UIButton] in
            if let button = subview as? UIButton {
                return [button]
            }
            return buttons(in: subview)
        }
    }

    private func segmentedControls(in view: UIView) -> [UISegmentedControl] {
        view.subviews.flatMap { subview -> [UISegmentedControl] in
            if let control = subview as? UISegmentedControl {
                return [control]
            }
            return segmentedControls(in: subview)
        }
    }
}

private final class StatsActionSpy: NSObject, SiteStatsInsightsDelegate, StatsTotalRowDelegate {
    var viewMoreSections: [StatSection] = []
    var openedURLs: [URL] = []
    var mediaIDs: [NSNumber] = []
    var toggledRows = 0
    var managedInsights: [StatSection] = []
    var dateChanges: [Date?] = []
    var customizeDismissTaps = 0
    var customizeTryTaps = 0
    var growAudienceDismissedHints: [GrowAudienceCell.HintType] = []
    var postSharingTaps = 0
    var postingActivityDetailsTaps = 0

    func viewMoreSelectedForStatSection(_ statSection: StatSection) { viewMoreSections.append(statSection) }
    func displayWebViewWithURL(_ url: URL) { openedURLs.append(url) }
    func displayMediaWithID(_ mediaID: NSNumber) { mediaIDs.append(mediaID) }
    func toggleChildRows(for row: StatsTotalRow, didSelectRow: Bool) { toggledRows += 1 }
    func manageInsightSelected(_ insight: StatSection, fromButton: UIButton) { managedInsights.append(insight) }
    func dateChangedTo(_ newDate: Date?) { dateChanges.append(newDate) }
    func customizeDismissButtonTapped() { customizeDismissTaps += 1 }
    func customizeTryButtonTapped() { customizeTryTaps += 1 }
    func growAudienceDismissButtonTapped(_ hintType: GrowAudienceCell.HintType) {
        growAudienceDismissedHints.append(hintType)
    }
    func growAudienceEnablePostSharingButtonTapped() { postSharingTaps += 1 }
    func showPostingActivityDetails() { postingActivityDetailsTaps += 1 }
}

private final class PostingDaySpy: PostingActivityDayDelegate {
    var selectedDays: [PostingActivityDay] = []
    func daySelected(_ day: PostingActivityDay) { selectedDays.append(day) }
}

private final class ViewsVisitorsSpy: StatsInsightsViewsAndVisitorsDelegate {
    var selectedSegments: [Int] = []
    func viewsAndVisitorsSegmendChanged(to selectedSegmentIndex: Int) { selectedSegments.append(selectedSegmentIndex) }
}

extension StatsActionSpy: ViewMoreRowDelegate, SiteStatsTableHeaderDelegate {}
