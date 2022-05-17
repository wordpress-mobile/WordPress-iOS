import Foundation
import XCTest
@testable import WordPress

class SiteStatsInsightsViewModelTests: XCTestCase {

    /// The standard api result for a normal user
    func testSummarySplitIntervalData14DaysBasecase() throws {
        // Given statsSummaryTimeIntervalData with 14 days data
        guard let statsSummaryTimeIntervalData = try! createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-14.json") else {
            XCTFail("Failed to create statsSummaryTimeIntervalData")
            return
        }

        // When splitting into thisWeek and prevWeek
        validateResults(SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(statsSummaryTimeIntervalData))
    }

    /// The api result for a new user that has full data for this week but a partial dataset for the previous week
    func testSummarySplitIntervalData11Days() throws {
        // Given statsSummaryTimeIntervalData with 11 days data
        guard let statsSummaryTimeIntervalData = try! createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-11.json") else {
            XCTFail(Constants.failCreateStatsSummaryTimeIntervalData)
            return
        }

        // When splitting into thisWeek and prevWeek
        validateResults(SiteStatsInsightsViewModel.splitStatsSummaryTimeIntervalData(statsSummaryTimeIntervalData))
    }

    /// The api result for a new user that has an incomplete dataset for this week and no data for prev week
    func testSummarySplitIntervalData4Days() throws {
        // Given statsSummaryTimeIntervalData with 4 days data
        guard let statsSummaryTimeIntervalData = try! createStatsSummaryTimeIntervalData(fileName: "stats-visits-day-4.json") else {
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

    func convertStringToDictionary(text: String) -> [String: AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }

    func createStatsSummaryTimeIntervalData(fileName: String) throws -> StatsSummaryTimeIntervalData? {
        let feb21 = DateComponents(year: 2019, month: 2, day: 21)
        let date = Calendar.autoupdatingCurrent.date(from: feb21)!

        let data = try load(fileName: fileName, fromBundle: Bundle(for: type(of: self)))
        let str = String(decoding: data, as: UTF8.self)
        let jsonDictionary = convertStringToDictionary(text: str)

        guard let json = jsonDictionary else {
            return nil
        }

        guard let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(date: date,
                period: .day,
                jsonDictionary: json) else {
            XCTFail()
            return nil
        }

        return statsSummaryTimeIntervalData
    }

    func load(fileName: String, fromBundle bundle: Bundle) throws -> Data {
        let fileUrl = URL(fileURLWithPath: fileName)
        let baseName = fileUrl.deletingPathExtension().path
        let ext = fileUrl.pathExtension

        guard let path = bundle.path(forResource: baseName, ofType: ext) else { XCTFail("Could not find file: \(fileName)"); throw NSError() }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else { XCTFail("Could not load data from file: \(fileName)"); throw NSError() }
        return data
    }
}

private extension SiteStatsInsightsViewModelTests {
    enum Constants {
        static let failCreateStatsSummaryTimeIntervalData = "Failed to create statsSummaryTimeIntervalData"
    }
}
