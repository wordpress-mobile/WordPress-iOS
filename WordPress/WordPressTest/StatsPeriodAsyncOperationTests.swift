import XCTest
@testable import WordPress
@testable import WordPressKit

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
        override func getData<TimeStatsType: StatsTimeIntervalData>(for period: StatsPeriodUnit,
                                                                    endingOn: Date,
                                                                    limit: Int = 10,
                                                                    completion: @escaping ((TimeStatsType?, Error?) -> Void)) {
            let mockType = TimeStatsType(date: endingOn,
                                         period: period,
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
