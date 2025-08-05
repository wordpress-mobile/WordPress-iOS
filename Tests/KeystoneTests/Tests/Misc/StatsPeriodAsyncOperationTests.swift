import XCTest
import WordPressKit

@testable import WordPress

class StatsPeriodAsyncOperationTests: XCTestCase {
    private let date = Date()
    private let operationQueue = OperationQueue()
    private lazy var mockRemoteService: MockStatsServiceRemoteV2 = {
        return MockStatsServiceRemoteV2(wordPressComRestApi: MockWordPressComRestApi(),
                                        siteID: 0,
                                        siteTimezone: TimeZone.current)
    }()

    func testStatsPeriodOperation() {
        let expect = expectation(description: "Add Stats Period Operation")
        let operation = StatsPeriodAsyncOperation(service: mockRemoteService, for: .day, date: date) { [unowned self] (item: MockStatsType?, error: Error?) in
            XCTAssertNotNil(item)
            XCTAssertTrue(item?.period == .day)
            XCTAssertTrue(item?.periodEndDate == self.date)
            expect.fulfill()
        }

        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 2, handler: nil)
    }
}

private extension StatsPeriodAsyncOperationTests {
    class MockStatsServiceRemoteV2: StatsServiceRemoteV2 {
        override func getData<TimeStatsType>(
            for period: StatsPeriodUnit,
            unit: StatsPeriodUnit? = nil,
            startDate: Date? = nil,
            endingOn: Date,
            limit: Int = 10,
            summarize: Bool? = nil,
            parameters: [String: String]? = nil,
            completion: @escaping (TimeStatsType?, (any Error)?) -> Void
        ) where TimeStatsType: StatsTimeIntervalData {
            let mockType = TimeStatsType(date: endingOn,
                                         period: period,
                                         unit: unit,
                                         jsonDictionary: [:])
            completion(mockType, nil)
        }
    }

    struct MockStatsType: StatsTimeIntervalData {
        static var pathComponent: String {
            return "test/path"
        }

        var period: StatsPeriodUnit
        var periodEndDate: Date
        var jsonDictionary: [String: AnyObject]

        init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
            self.periodEndDate = date
            self.period = period
            self.jsonDictionary = jsonDictionary
        }
    }
}
