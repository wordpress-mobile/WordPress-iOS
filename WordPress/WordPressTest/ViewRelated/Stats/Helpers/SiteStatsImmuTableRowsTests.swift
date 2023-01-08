import Foundation
import XCTest
@testable import WordPress

class SiteStatsImmuTableRowsTests: XCTestCase {

    func testViewVisitorsImmuTableRows() throws {
        // Given statsSummaryTimeIntervalData with 14 days data
        guard let statsSummaryTimeIntervalData = try! StatsMockDataLoader.createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-14.json") else {
            XCTFail("Failed to create statsSummaryTimeIntervalData")
            return
        }

        let feb21 = DateComponents(year: 2019, month: 2, day: 21)
        let date = Calendar.autoupdatingCurrent.date(from: feb21)!

        // When creating rows from statsSummaryTimeIntervalData
        let rows = SiteStatsImmuTableRows.viewVisitorsImmuTableRows(statsSummaryTimeIntervalData, selectedSegment: .views, periodDate: date, statsLineChartViewDelegate: nil, siteStatsInsightsDelegate: nil, viewsAndVisitorsDelegate: nil)

        // Then
        XCTAssertTrue(rows.count == 1)
    }
}
