import UIKit
import XCTest
import Nimble

@testable import WordPress

class ReaderTrackerTests: XCTestCase {

    /// Return 20s as the time spent in Reader
    ///
    func testTrackTimeSpentInMainReader() {
        let nowMock = DispatchTimeMock(startTime: 0, endTime: 20_000_000_000)
        let tracker = ReaderTracker(now: nowMock.now)
        tracker.start(.main)

        tracker.stop(.main)

        expect(tracker.data()).to(equal([
            "time_in_main_reader": 20,
            "time_in_reader_filtered_list": 0,
            "time_in_reader_post": 0
        ]))
    }

    /// Return 16s as the time spent in filtered list
    ///
    func testTrackTimeSpentInFilteredList() {
        let nowMock = DispatchTimeMock(startTime: 0, endTime: 15_500_000_000)
        let tracker = ReaderTracker(now: nowMock.now)
        tracker.start(.filteredList)

        tracker.stop(.filteredList)

        expect(tracker.data()).to(equal([
            "time_in_main_reader": 0,
            "time_in_reader_filtered_list": 16,
            "time_in_reader_post": 0
        ]))
    }

}

class DispatchTimeMock {
    private let startTime: UInt64
    private let endTime: UInt64
    var called = 0

    init(startTime: UInt64, endTime: UInt64) {
        self.startTime = startTime
        self.endTime = endTime
    }

    func now() -> UInt64 {
        called += 1
        return called == 1 ? startTime : endTime
    }
}
