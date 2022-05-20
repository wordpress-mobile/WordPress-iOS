import Foundation
import XCTest

struct StatsMockDataLoader {

    static func createStatsSummaryTimeIntervalData(fileName: String) throws -> StatsSummaryTimeIntervalData? {
        let feb21 = DateComponents(year: 2019, month: 2, day: 21)
        let date = Calendar.autoupdatingCurrent.date(from: feb21)!

        let jsonDictionary = try JSONObject.init(fromFileNamed: fileName)

        guard let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(date: date,
                period: .day,
                jsonDictionary: jsonDictionary) else {
            XCTFail()
            return nil
        }

        return statsSummaryTimeIntervalData
    }
}
