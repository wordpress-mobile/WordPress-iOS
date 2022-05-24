import Foundation
import XCTest
@testable import WordPress

class SiteStatsInsightsViewModelTests: XCTestCase {

    /// The standard api result for a normal user
    func testSummarySplitIntervalData14DaysBasecase() throws {
        // Given statsSummaryTimeIntervalData with 14 days data
        guard let statsSummaryTimeIntervalData = try! StatsMockDataLoader.createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-14.json") else {
            XCTFail("Failed to create statsSummaryTimeIntervalData")
            return
        }

        // When splitting into thisWeek and prevWeek
        validateResults(SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(statsSummaryTimeIntervalData))
    }

    /// The api result for a new user that has full data for this week but a partial dataset for the previous week
    func testSummarySplitIntervalData11Days() throws {
        // Given statsSummaryTimeIntervalData with 11 days data
        guard let statsSummaryTimeIntervalData = try! StatsMockDataLoader.createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-11.json") else {
            XCTFail(Constants.failCreateStatsSummaryTimeIntervalData)
            return
        }

        // When splitting into thisWeek and prevWeek
        validateResults(SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(statsSummaryTimeIntervalData))
    }

    /// The api result for a new user that has an incomplete dataset for this week and no data for prev week
    func testSummarySplitIntervalData4Days() throws {
        // Given statsSummaryTimeIntervalData with 4 days data
        guard let statsSummaryTimeIntervalData = try! StatsMockDataLoader.createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-4.json") else {
            XCTFail(Constants.failCreateStatsSummaryTimeIntervalData)
            return
        }

        // When splitting into thisWeek and prevWeek
        validateResults(SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(statsSummaryTimeIntervalData))
    }

    func validateResults(_ statsSummaryTimeIntervalDataAsAWeeks: [StatsSummaryTimeIntervalDataAsAWeek]) {
        XCTAssertTrue(statsSummaryTimeIntervalDataAsAWeeks.count == 2)

        // Then 14 days should be split into thisWeek and nextWeek evenly
        statsSummaryTimeIntervalDataAsAWeeks.forEach { week in
            switch week {
            case .thisWeek(let thisWeek):
                XCTAssertTrue(thisWeek.summaryData.count == 7)
                XCTAssertEqual(thisWeek.summaryData.last?.periodStartDate, Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 2, day: 21)))
                XCTAssertEqual(thisWeek.summaryData.first?.periodStartDate, Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 2, day: 15)))
            case .prevWeek(let prevWeek):
                XCTAssertTrue(prevWeek.summaryData.count == 7)
                XCTAssertEqual(prevWeek.summaryData.last?.periodStartDate, Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 2, day: 14)))
                XCTAssertEqual(prevWeek.summaryData.first?.periodStartDate, Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 2, day: 8)))
            }
        }
    }
}

private extension SiteStatsInsightsViewModelTests {
    enum Constants {
        static let failCreateStatsSummaryTimeIntervalData = "Failed to create statsSummaryTimeIntervalData"
    }
}
